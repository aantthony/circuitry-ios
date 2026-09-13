//
//  MongoIDTest.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MongoID.h"
#import "Circuit.h"
#import "CircuitTest.h"
#import "ProblemSet.h"
#import "CircuitDocument.h"
#import "Viewport.h"
#import "ViewController.h"

@interface ViewController (ClockTesting)
- (void)sceneDidUpdateAtTime:(NSTimeInterval)currentTime;
@end

@interface ClockTestViewController : ViewController
@end
@implementation ClockTestViewController
- (void)loadView {
    self.view = [[NSClassFromString(@"CircuitCanvasView") alloc] initWithFrame:CGRectMake(0, 0, 600, 600)];
}
@end
#import <SpriteKit/SpriteKit.h>

@interface MongoIDTest : XCTestCase

@end

@implementation MongoIDTest

- (void)testHistoryToolbarDisablesWhenUndoOrRedoIsExhausted {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:@"/tmp/history-toolbar-test.circuit"]];
    document.circuit = [[Circuit alloc] initWithPackage:@{} items:@[]];
    ClockTestViewController *editor = [[ClockTestViewController alloc] init];
    editor.document = document;
    XCTAssertFalse(editor.undoBarButtonItem.enabled);
    XCTAssertFalse(editor.redoBarButtonItem.enabled);

    [document beginCircuitEdit:@"Rename"];
    document.circuit.title = @"First edit";
    [document finishCircuitEdit];
    XCTAssertTrue(editor.undoBarButtonItem.enabled);
    XCTAssertFalse(editor.redoBarButtonItem.enabled);

    [document.editorUndoManager undo];
    XCTAssertFalse(editor.undoBarButtonItem.enabled);
    XCTAssertTrue(editor.redoBarButtonItem.enabled);
    [document.editorUndoManager redo];
    XCTAssertTrue(editor.undoBarButtonItem.enabled);
    XCTAssertFalse(editor.redoBarButtonItem.enabled);

    [document.editorUndoManager undo];
    [document beginCircuitEdit:@"Rename"];
    document.circuit.title = @"Replacement edit";
    [document finishCircuitEdit];
    XCTAssertTrue(editor.undoBarButtonItem.enabled);
    XCTAssertFalse(editor.redoBarButtonItem.enabled);
}

- (void)testCircuitUndoPreservesExactPendingSimulationWork {
    for (NSNumber *settled in @[@NO, @YES]) {
        CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:@"/tmp/undo-state-test.circuit"]];
        document.circuit = [[Circuit alloc] initWithPackage:@{} items:@[]];
        [document.circuit performWriteBlock:^(CircuitInternal *internal) {
            CircuitObject *object = CircuitObjectCreate(internal, &CircuitProcessD);
            object->id = [MongoID id];
        }];
        if (settled.boolValue) [document.circuit simulate:512];
        NSDictionary *original = [document.circuit captureSimulationState];
        [document beginCircuitEdit:@"Rename"];
        document.circuit.title = @"Renamed";
        [document finishCircuitEdit];
        [document.editorUndoManager undo];
        XCTAssertEqualObjects([document.circuit captureSimulationState], original);
        [document.editorUndoManager redo];
        XCTAssertEqualObjects([document.circuit captureSimulationState], original);
        if (settled.boolValue) XCTAssertEqual([document.circuit simulate:512], 0);
    }
}

- (void)testCircuitUndoRestoresDeletedComponentWiringAndNotes {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:@"/tmp/undo-test.circuit"]];
    document.circuit = [[Circuit alloc] initWithPackage:@{ @"title": @"Undo test", @"hints": @[@"Keep me"] } items:@[]];
    __block NSString *sourceID;
    __block NSString *targetID;
    [document beginCircuitEdit:@"Build Circuit"];
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObject *source = CircuitObjectCreate(internal, &CircuitProcessButton);
        source->id = [MongoID id];
        sourceID = [MongoID stringWithId:source->id];
        source->pos.x = 99;
        strlcpy(source->name, "CLK", sizeof(source->name));
        CircuitObject *target = CircuitObjectCreate(internal, &CircuitProcessLight);
        target->id = [MongoID id];
        targetID = [MongoID stringWithId:target->id];
        CircuitLinkCreate(internal, source, 0, target, 0);
    }];
    [document.circuit.notes addObject:[[CircuitNote alloc] initWithDictionary:@{ @"text": @"Wired", @"rect": @[@0, @0, @200, @100] }]];
    [document finishCircuitEdit];
    [document beginCircuitEdit:@"Delete"];
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObjectRemove(internal, [document.circuit findObjectById:sourceID]);
    }];
    [document.circuit.notes removeAllObjects];
    [document finishCircuitEdit];
    [document.editorUndoManager undo];
    CircuitObject *restored = [document.circuit findObjectById:sourceID];
    XCTAssertNotEqual(restored, NULL);
    XCTAssertEqual(restored->pos.x, 99);
    XCTAssertEqualObjects([NSString stringWithUTF8String:restored->name], @"CLK");
    XCTAssertEqual(restored->outputs[0]->target, [document.circuit findObjectById:targetID]);
    XCTAssertEqualObjects(document.circuit.notes.firstObject.text, @"Wired");
    XCTAssertEqualObjects(document.circuit.hints, @[@"Keep me"]);
    [document.editorUndoManager redo];
    XCTAssertEqual([document.circuit findObjectById:sourceID], NULL);
    XCTAssertEqual(document.circuit.notes.count, 0u);
    [document.editorUndoManager undo];
    [document.editorUndoManager undo];
    XCTAssertEqual([document.circuit findObjectById:targetID], NULL);
    XCTAssertFalse(document.editorUndoManager.canUndo);
}

- (void)testCircuitUndoGroupsDragsIgnoresSimulationAndClearsRedoOnNewEdit {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:@"/tmp/undo-drag-test.circuit"]];
    document.circuit = [[Circuit alloc] initWithPackage:@{} items:@[]];
    __block NSString *objectID;
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObject *object = CircuitObjectCreate(internal, &CircuitProcessClock);
        object->id = [MongoID id];
        objectID = [MongoID stringWithId:object->id];
    }];
    [document beginCircuitEdit:@"No Movement"];
    [document.circuit findObjectById:objectID]->out = 1;
    [document finishCircuitEdit];
    XCTAssertFalse(document.editorUndoManager.canUndo);
    [document beginCircuitEdit:@"Move"];
    for (int i = 0; i < 100; i++) [document.circuit findObjectById:objectID]->pos.x = i;
    [document finishCircuitEdit];
    [document.editorUndoManager undo];
    XCTAssertEqual([document.circuit findObjectById:objectID]->pos.x, 0);
    XCTAssertFalse(document.editorUndoManager.canUndo);
    XCTAssertTrue(document.editorUndoManager.canRedo);
    [document beginCircuitEdit:@"Rename"];
    document.circuit.title = @"New branch";
    [document finishCircuitEdit];
    XCTAssertFalse(document.editorUndoManager.canRedo);
    [document.editorUndoManager undo];
    XCTAssertEqualObjects(document.circuit.title, @"");
}

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testPausedSimulationStepsOneEdgeWithoutCatchingUp {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:
        [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"clock-step-test"]]];
    document.circuit = [[Circuit alloc] initWithPackage:@{@"_id": @"000000000000000000000001"} items:@[]];
    __block CircuitObject *fast, *slow, *counter;
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        fast = CircuitObjectCreate(internal, &CircuitProcessClock);
        slow = CircuitObjectCreate(internal, &CircuitProcessSlowClock);
        counter = CircuitObjectCreate(internal, &CircuitProcessCounter4);
        CircuitLinkCreate(internal, slow, 0, counter, 0);
    }];
    ClockTestViewController *editor = [[ClockTestViewController alloc] init];
    editor.document = document;
    editor.simulationPaused = YES;
    [editor sceneDidUpdateAtTime:1];
    [editor sceneDidUpdateAtTime:100];
    XCTAssertEqual(fast->out, 0);
    XCTAssertEqual(slow->out, 0);
    XCTAssertEqual(counter->out, 0);
    [editor stepClock];
    XCTAssertTrue(editor.simulationPaused);
    XCTAssertEqual(fast->out, 1);
    XCTAssertEqual(slow->out, 1);
    XCTAssertEqual(counter->out, 1);
    [editor sceneDidUpdateAtTime:101];
    [editor sceneDidUpdateAtTime:200];
    XCTAssertEqual(counter->out, 1);
    [editor stepClock];
    XCTAssertEqual(slow->out, 0);
    XCTAssertEqual(counter->out, 1); // A falling edge does not increment.
    [editor stepClock];
    XCTAssertEqual(counter->out, 2);
    editor.simulationPaused = NO;
    [editor sceneDidUpdateAtTime:1000];
    XCTAssertEqual(fast->out, 1); // No accumulated paused-time transitions.
    XCTAssertEqual(counter->out, 2);
    [editor sceneDidUpdateAtTime:1000.5];
    XCTAssertEqual(slow->out, 0);
    [editor sceneDidUpdateAtTime:1001];
    XCTAssertEqual(counter->out, 3);
}

- (void)testExample
{
    NSScanner *scanner = [NSScanner scannerWithString:@"33"];
    scanner.scanLocation = 0;
    unsigned int a;
    [scanner scanHexInt:&a];
    assert(a == 0x33);
    
    ObjectID _id = [MongoID id];
    NSString *str = [MongoID stringWithId:_id];
    ObjectID _id2 = [MongoID idWithString:str];
    if (_id2.m[0] != _id.m[0] || _id2.m[1] != _id.m[1] || _id2.m[2] != _id.m[2]) {
        XCTFail(@"Expected \"%@\" to match", str);
    }
    
}

- (void)testCircuitNotesRoundTripTheirTextAndRectangle
{
    NSDictionary *saved = @{
        @"_id": @"note-1",
        @"text": @"Control section",
        @"rect": @[@12.5, @30.0, @640.0, @180.0]
    };
    CircuitNote *note = [[CircuitNote alloc] initWithDictionary:saved];

    XCTAssertEqualObjects(note.identifier, @"note-1");
    XCTAssertEqualObjects(note.text, @"Control section");
    XCTAssertTrue(CGRectEqualToRect(note.frame, CGRectMake(12.5, 30.0, 640.0, 180.0)));
    XCTAssertEqualObjects(note.dictionaryRepresentation, saved);
}

- (void)testCircuitLoadsNotesWithoutTreatingThemAsSimulationObjects
{
    NSDictionary *package = @{
        @"name": @"notes-test",
        @"version": @"1",
        @"title": @"Notes",
        @"author": @"",
        @"license": @"",
        @"notes": @[@{@"text": @"A note", @"rect": @[@0, @0, @300, @120]}]
    };
    Circuit *circuit = [[Circuit alloc] initWithPackage:package items:@[]];

    XCTAssertEqual(circuit.notes.count, 1u);
    XCTAssertEqualObjects(circuit.notes.firstObject.text, @"A note");
    __block NSUInteger objectCount = 0;
    [circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        objectCount++;
    }];
    XCTAssertEqual(objectCount, 0u);
}


- (void)testDuplicateSelectionPreservesInternalFanoutAndIsPlaygroundOnly {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"duplicate-test.circuit"]]];
    document.circuit = [[Circuit alloc] initWithPackage:@{@"name": @"duplicate", @"version": @"1"} items:@[]];
    __block NSString *buttonID, *lightID, *externalID;
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObject *button = CircuitObjectCreate(internal, &CircuitProcessButton);
        button->id = [MongoID id];
        button->pos.x = 33; button->pos.y = 66;
        strlcpy(button->name, "CLK", sizeof(button->name));
        buttonID = [MongoID stringWithId:button->id];
        CircuitObject *light = CircuitObjectCreate(internal, &CircuitProcessLight);
        light->id = [MongoID id];
        lightID = [MongoID stringWithId:light->id];
        CircuitObject *external = CircuitObjectCreate(internal, &CircuitProcessLight);
        external->id = [MongoID id];
        externalID = [MongoID stringWithId:external->id];
        CircuitLinkCreate(internal, button, 0, light, 0);
        CircuitLinkCreate(internal, button, 0, external, 0);
        CircuitObjectSetOutput(internal, button, 1);
    }];
    [document.circuit simulate:512];
    NSArray *copies = [document duplicateObjectsWithIDs:@[buttonID, lightID, buttonID] offset:CGVectorMake(99, 132)];
    XCTAssertEqual(copies.count, 2u);
    CircuitObject *buttonCopy = [document.circuit findObjectById:copies[0]];
    CircuitObject *lightCopy = [document.circuit findObjectById:copies[1]];
    XCTAssertNotEqualObjects(copies[0], buttonID);
    XCTAssertNotEqualObjects(copies[1], lightID);
    XCTAssertEqualObjects([NSString stringWithUTF8String:buttonCopy->name], @"CLK");
    XCTAssertEqual(buttonCopy->pos.x, 132);
    XCTAssertEqual(buttonCopy->pos.y, 198);
    XCTAssertEqual(buttonCopy->outputs[0]->target, lightCopy);
    XCTAssertEqual(buttonCopy->outputs[0]->nextSibling, NULL);
    XCTAssertEqual(lightCopy->inputs[0]->source, buttonCopy);
    XCTAssertEqual([document.circuit findObjectById:externalID]->inputs[0]->source, [document.circuit findObjectById:buttonID]);
    [document.circuit simulate:512];
    XCTAssertEqual(lightCopy->in, 1);
    [document.editorUndoManager undo];
    XCTAssertEqual([document.circuit findObjectById:copies[0]], NULL);
    XCTAssertNotEqual([document.circuit findObjectById:buttonID], NULL);
    [document.editorUndoManager redo];
    XCTAssertNotEqual([document.circuit findObjectById:copies[0]], NULL);
    document.problemInfo = [[ProblemSetProblemInfo alloc] init];
    XCTAssertEqual([document duplicateObjectsWithIDs:@[buttonID] offset:CGVectorMake(99, 99)].count, 0u);
}

- (void)testDuplicateSelectionDoesNotCopyIncomingExternalWires {
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"duplicate-boundary.circuit"]]];
    document.circuit = [[Circuit alloc] initWithPackage:@{@"name": @"duplicate", @"version": @"1"} items:@[]];
    __block NSString *lightID;
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObject *button = CircuitObjectCreate(internal, &CircuitProcessButton);
        button->id = [MongoID id];
        CircuitObject *light = CircuitObjectCreate(internal, &CircuitProcessLight);
        light->id = [MongoID id];
        lightID = [MongoID stringWithId:light->id];
        CircuitLinkCreate(internal, button, 0, light, 0);
        CircuitObjectSetOutput(internal, button, 1);
    }];
    NSArray *copies = [document duplicateObjectsWithIDs:@[lightID] offset:CGVectorMake(33, 33)];
    CircuitObject *copy = [document.circuit findObjectById:copies.firstObject];
    XCTAssertEqual(copy->inputs[0], NULL);
    XCTAssertEqual(copy->in, 0);
    XCTAssertEqual([document duplicateObjectsWithIDs:@[@"000000000000000000000000"] offset:CGVectorMake(33, 33)].count, 0u);
}

- (void)testFailedCheckInspectionRestoresExactSimulationState {
    Circuit *circuit = [[Circuit alloc] initWithPackage:@{@"name": @"inspection", @"version": @"1"} items:@[]];
    __block CircuitObject *input;
    __block CircuitObject *output;
    [circuit performWriteBlock:^(CircuitInternal *internal) {
        input = CircuitObjectCreate(internal, &CircuitProcessIn);
        input->id = [MongoID id];
        output = CircuitObjectCreate(internal, &CircuitProcessOut);
        output->id = [MongoID id];
        CircuitLinkCreate(internal, input, 0, output, 0);
        // Preserve a queued transition and sequential state across test execution.
        CircuitObjectSetOutput(internal, input, 1);
        input->data = 42;
    }];
    NSDictionary *before = [circuit captureSimulationState];
    CircuitTest *test = [[CircuitTest alloc] initWithName:@"Mismatch"
        inputs:@[[NSValue valueWithPointer:input]] outputs:@[[NSValue valueWithPointer:output]]
        spec:@[@[@[@0], @[@1]], @[@[@1], @[@1]]] acceptedSpecs:nil];
    CircuitTestResult *result = [test runAndSimulate:circuit];
    XCTAssertFalse(result.passed);
    XCTAssertEqualObjects(before, [circuit captureSimulationState]);
    CircuitTestResultCheck *failed = result.checks[0];
    XCTAssertFalse(failed.isMatch);
    XCTAssertEqualObjects(failed.actualOutputs, @[@0]);
    XCTAssertEqualObjects(failed.mismatchingOutputIDs, @[[MongoID stringWithId:output->id]]);
    XCTAssertTrue(((CircuitTestResultCheck *)result.checks[1]).isMatch);
    [circuit restoreSimulationState:failed.simulationState];
    XCTAssertEqual(input->out, 0);
    XCTAssertEqual(output->in, 0);
    [circuit restoreSimulationState:before];
    XCTAssertEqualObjects(before, [circuit captureSimulationState]);
    XCTAssertEqual(input->data, 42u);
    [circuit simulate:512];
    XCTAssertEqual(output->in, 1);
}

- (void)testProgressMigrationAndNewLevels {
    NSString *suite = [@"ProgressTests-" stringByAppendingString:NSUUID.UUID.UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
    NSString *path = [NSBundle.mainBundle pathForResource:@"Problems" ofType:nil];
    @try {
        for (NSNumber *legacy in @[@0, @5, @21, @22, @999]) {
            [defaults removePersistentDomainForName:suite];
            [defaults setInteger:legacy.integerValue forKey:@"CurrentLevelIndex"];
            ProblemSet *set = [[ProblemSet alloc] initWithDirectoryPath:path defaults:defaults];
            NSUInteger expected = legacy.integerValue == 999 ? 21 : legacy.unsignedIntegerValue;
            for (NSUInteger i = 0; i < set.problems.count; i++) {
                ProblemSetProblemInfo *info = set.problems[i];
                XCTAssertEqual(info.isCompleted, i < expected);
            }
            ProblemSetProblemInfo *alu = set.problems.lastObject;
            XCTAssertEqualObjects(alu.documentURL.lastPathComponent, @"024");
            if (legacy.integerValue == 999 || legacy.integerValue == 21) {
                XCTAssertTrue(alu.isAccessible);
                XCTAssertFalse(alu.isCompleted);
            }
        }
        [defaults removePersistentDomainForName:suite];
        ProblemSet *set = [[ProblemSet alloc] initWithDirectoryPath:path defaults:defaults];
        [set unlockAll];
        for (ProblemSetProblemInfo *info in set.problems) {
            XCTAssertTrue(info.isAccessible);
            XCTAssertFalse(info.isCompleted);
        }
        [set didCompleteProblem:set.problems.lastObject];
        XCTAssertTrue(((ProblemSetProblemInfo *)set.problems.lastObject).isCompleted);
        XCTAssertFalse(((ProblemSetProblemInfo *)set.problems.firstObject).isCompleted);
        set = [[ProblemSet alloc] initWithDirectoryPath:path defaults:defaults];
        XCTAssertTrue(((ProblemSetProblemInfo *)set.problems.lastObject).isCompleted);
        // A future catalog entry is never implicitly completed.
        XCTAssertEqualObjects([defaults arrayForKey:@"CompletedProblemPaths"], (@[@"024"]));
        NSString *catalog = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [NSFileManager.defaultManager createDirectoryAtPath:catalog withIntermediateDirectories:YES attributes:nil error:NULL];
        NSDictionary *index = @{@"problems": @[
            @{@"path": @"025", @"title": @"Future level"},
            @{@"path": @"024", @"title": @"ALU moved"},
            @{@"path": @"001", @"title": @"First level moved"}]};
        NSData *data = [NSJSONSerialization dataWithJSONObject:index options:0 error:NULL];
        [data writeToFile:[catalog stringByAppendingPathComponent:@"index.json"] atomically:YES];
        ProblemSet *reordered = [[ProblemSet alloc] initWithDirectoryPath:catalog defaults:defaults];
        XCTAssertFalse(((ProblemSetProblemInfo *)reordered.problems[0]).isCompleted);
        XCTAssertTrue(((ProblemSetProblemInfo *)reordered.problems[1]).isCompleted);
        XCTAssertFalse(((ProblemSetProblemInfo *)reordered.problems[2]).isCompleted);
        [NSFileManager.defaultManager removeItemAtPath:catalog error:NULL];
        [set reset];
        XCTAssertTrue(((ProblemSetProblemInfo *)set.problems.firstObject).isAccessible);
        XCTAssertFalse(((ProblemSetProblemInfo *)set.problems.lastObject).isAccessible);
        XCTAssertFalse(((ProblemSetProblemInfo *)set.problems.lastObject).isCompleted);
    } @finally {
        [defaults removePersistentDomainForName:suite];
    }
}

// Artifact capture and renderer smoke test, using the editor atlas and SpriteKit renderer.
- (void)testCaptureALUThumbnail {
    NSString *path = [[NSBundle.mainBundle pathForResource:@"Problems" ofType:nil]
                     stringByAppendingPathComponent:@"024/package.json"];
    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                           options:0 error:NULL];
    CircuitDocument *document = [[CircuitDocument alloc] initWithFileURL:
        [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"alu-thumbnail"]]];
    document.circuit = [[Circuit alloc] initWithPackage:package items:package[@"items"]];
    // Arrange the actual level terminals for a compact card, with the available
    // operation gates as an unwired preview (no solution is supplied).
    [document.circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        if (strcmp(object->name, "A") == 0) object->pos = (typeof(object->pos)){.x=60, .y=100};
        if (strcmp(object->name, "B") == 0) object->pos = (typeof(object->pos)){.x=60, .y=290};
        if (strcmp(object->name, "Cin") == 0) object->pos = (typeof(object->pos)){.x=60, .y=480};
        if (strcmp(object->name, "S1") == 0) object->pos = (typeof(object->pos)){.x=60, .y=740};
        if (strcmp(object->name, "S0") == 0) object->pos = (typeof(object->pos)){.x=60, .y=930};
        if (strcmp(object->name, "R") == 0) object->pos = (typeof(object->pos)){.x=890, .y=320};
        if (strcmp(object->name, "Co") == 0) object->pos = (typeof(object->pos)){.x=890, .y=740};
    }];
    [document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitProcess *types[] = {&CircuitProcessAnd, &CircuitProcessOr, &CircuitProcessXor, &CircuitProcessFA};
        for (int i=0; i<4; i++) {
            CircuitObject *gate = CircuitObjectCreate(internal, types[i]);
            gate->pos.x = 470; gate->pos.y = 120 + i*240;
        }
    }];
    SKView *view = [[SKView alloc] initWithFrame:CGRectMake(0, 0, 600, 600)];
    SKScene *scene = [SKScene sceneWithSize:view.bounds.size];
    [view presentScene:scene];
    Viewport *viewport = [[Viewport alloc] initWithAtlas:[ImageAtlas imageAtlasWithName:@"circuit"]];
    viewport.document = document;
    viewport.translation = CGPointZero;
    viewport.zoomScale = 0.5;
    [viewport attachToScene:scene backgroundImage:[UIImage imageNamed:@"background.jpg"]];
    [viewport updateSceneForViewSize:view.bounds.size allowContentRebuild:YES];
    CGImageRef cgImage = [view textureFromNode:scene crop:scene.frame].CGImage;
    XCTAssertTrue(cgImage != NULL);
    if (!cgImage) return;
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    XCTAttachment *attachment = [XCTAttachment attachmentWithImage:image];
    attachment.name = @"level-024";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end
