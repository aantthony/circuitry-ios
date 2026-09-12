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
#import "ProblemSet.h"
#import "CircuitDocument.h"
#import "Viewport.h"
#import <SpriteKit/SpriteKit.h>

@interface MongoIDTest : XCTestCase

@end

@implementation MongoIDTest

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
