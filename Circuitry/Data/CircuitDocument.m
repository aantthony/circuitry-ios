//
//  CircuitDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitDocument.h"
#import "AppDelegate.h"
#import "CircuitTest.h"
#import <AVFoundation/AVFoundation.h>

@interface CircuitDocument() <NSURLSessionTaskDelegate>
@property (nonatomic) NSData *originalScreenshotData;
@property (nonatomic) NSUndoManager *editorUndoManager;
@property (nonatomic) NSDictionary *pendingEditSnapshot;
@property (nonatomic) NSString *pendingEditName;
@property (nonatomic) BOOL needsScreenshotUpdate;
@property (nonatomic) NSError *loadError;
@end

NSString * const CircuitDocumentHistoryDidChangeNotification = @"CircuitDocumentHistoryDidChangeNotification";
NSString * const CircuitDocumentCircuitDidRestoreNotification = @"CircuitDocumentCircuitDidRestoreNotification";

static NSString *screenshotPngPath = @"screenshot.png";
static NSString *CircuitDocumentErrorDomain = @"CircuitDocumentErrorDomain";

static NSError *CircuitDocumentLoadError(NSString *message) {
    return [NSError errorWithDomain:CircuitDocumentErrorDomain
                               code:1
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSString *CircuitDocumentUnsupportedProcessType(NSArray *items) {
    NSDictionary *processesById = [Circuit processesById];
    for (NSDictionary *item in items) {
        NSString *type = item[@"type"];
        if (!type.length || !processesById[type]) {
            return type ?: @"";
        }
    }
    return nil;
}

@implementation CircuitDocument
- (NSUndoManager *)editorUndoManager {
    if (!_editorUndoManager) {
        _editorUndoManager = [[NSUndoManager alloc] init];
        _editorUndoManager.groupsByEvent = NO;
        _editorUndoManager.levelsOfUndo = 100;
    }
    return _editorUndoManager;
}

- (NSDictionary *)circuitEditSnapshot {
    NSMutableArray *notes = [NSMutableArray array];
    for (CircuitNote *note in self.circuit.notes) [notes addObject:note.dictionaryRepresentation];
    return @{ @"items": [self exportItems], @"notes": notes, @"title": self.circuit.title ?: @"",
              @"simulation": [self.circuit captureSimulationState] };
}

- (NSDictionary *)structureOfSnapshot:(NSDictionary *)snapshot {
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *item in snapshot[@"items"]) {
        NSMutableDictionary *copy = [item mutableCopy];
        // Simulation runs during gestures; clock transitions must not create edits.
        [copy removeObjectsForKeys:@[@"in", @"out", @"data"]];
        [items addObject:copy];
    }
    return @{ @"items": items, @"notes": snapshot[@"notes"], @"title": snapshot[@"title"] };
}

- (BOOL)circuitEditInProgress { return self.pendingEditSnapshot != nil; }

- (void)beginCircuitEdit:(NSString *)actionName {
    if (self.pendingEditSnapshot) return;
    self.pendingEditSnapshot = [self circuitEditSnapshot];
    self.pendingEditName = actionName;
    [[NSNotificationCenter defaultCenter] postNotificationName:CircuitDocumentHistoryDidChangeNotification object:self];
}

- (void)finishCircuitEdit {
    NSDictionary *before = self.pendingEditSnapshot;
    if (!before) return;
    NSString *name = self.pendingEditName;
    self.pendingEditSnapshot = nil;
    self.pendingEditName = nil;
    NSDictionary *after = [self circuitEditSnapshot];
    if (![[self structureOfSnapshot:before] isEqual:[self structureOfSnapshot:after]]) {
        [self.editorUndoManager beginUndoGrouping];
        [[self.editorUndoManager prepareWithInvocationTarget:self] restoreCircuitEditSnapshot:before actionName:name];
        [self.editorUndoManager setActionName:name];
        [self.editorUndoManager endUndoGrouping];
        if (!self.isProblem) [self updateChangeCount:UIDocumentChangeDone];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CircuitDocumentHistoryDidChangeNotification object:self];
}

- (void)restoreCircuitEditSnapshot:(NSDictionary *)snapshot actionName:(NSString *)name {
    NSDictionary *inverse = [self circuitEditSnapshot];
    NSMutableDictionary *package = [[self exportPackageDictionaryWithoutItems] mutableCopy];
    package[@"notes"] = snapshot[@"notes"];
    package[@"title"] = snapshot[@"title"];
    Circuit *restored = [[Circuit alloc] initWithPackage:package items:snapshot[@"items"]];
    if (!restored) return;
    restored.hints = self.circuit.hints;
    // Loading builds an initial propagation queue. Restore the original queue as
    // well as signal values so undo does not introduce extra sequential edges.
    [restored restoreSimulationState:snapshot[@"simulation"]];
    [[self.editorUndoManager prepareWithInvocationTarget:self] restoreCircuitEditSnapshot:inverse actionName:name];
    [self.editorUndoManager setActionName:name];
    self.circuit = restored;
    if (!self.isProblem) {
        [self updateChangeCount:self.editorUndoManager.isUndoing ? UIDocumentChangeUndone : UIDocumentChangeRedone];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CircuitDocumentCircuitDidRestoreNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:CircuitDocumentHistoryDidChangeNotification object:self];
}

- (void) setProblemInfo:(ProblemSetProblemInfo *)problemInfo {
    _isProblem = problemInfo != nil;
    _problemInfo = problemInfo;
}
- (instancetype) initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        // New documents do not have a screenshot until the editor has rendered
        // one, even though their initial package has already been saved.
        _needsScreenshotUpdate = YES;
    }
    return self;
}
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSError *err = nil;
    self.loadError = nil;
    
    if ([typeName isEqualToString:@"public.json"]) {
        NSDictionary *full = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&err];
        if (err) return NO;
        
        NSString *unsupportedType = CircuitDocumentUnsupportedProcessType(full[@"items"]);
        if (unsupportedType) {
            self.loadError = CircuitDocumentLoadError([NSString stringWithFormat:@"This circuit contains an unsupported object type: %@.", unsupportedType]);
            if (outError) *outError = self.loadError;
            return NO;
        }
        
        _circuit = [[Circuit alloc] initWithPackage:full items:full[@"items"]];
        if (!_circuit) {
            self.loadError = CircuitDocumentLoadError(@"This circuit file is invalid and could not be loaded.");
            if (outError) *outError = self.loadError;
            return NO;
        }
        return YES;
    }
    
    NSFileWrapper *wrapper = contents;
    NSDictionary *files = [wrapper fileWrappers];
    NSData *jsonData = [files[@"package.json"] regularFileContents];
    if (!jsonData) return NO;
    
    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
    if (err) return NO;
    
    NSArray *items = package[@"items"];
    
    if (!items) {
        items = [NSJSONSerialization JSONObjectWithData:[files[@"items.json"] regularFileContents] options:0 error:&err];
        if (err) return NO;
    }
    
    NSString *unsupportedType = CircuitDocumentUnsupportedProcessType(items);
    if (unsupportedType) {
        self.loadError = CircuitDocumentLoadError([NSString stringWithFormat:@"This circuit contains an unsupported object type: %@.", unsupportedType]);
        if (outError) *outError = self.loadError;
        return NO;
    }
    
    _originalScreenshotData = [files[screenshotPngPath] regularFileContents];
    _needsScreenshotUpdate = _originalScreenshotData == nil;
     
    _circuit = [[Circuit alloc] initWithPackage:package items: items];
    if (!_circuit) {
        self.loadError = CircuitDocumentLoadError(@"This circuit file is invalid and could not be loaded.");
        if (outError) *outError = self.loadError;
        return NO;
    }
    
    return YES;
}

- (void) useScreenshot:(UIImage *)image {
    UIImage *newImage;
    CGSize newSize = CGSizeMake(188, 188);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0); {
        CGSize scaledSize = newSize;
        
        CGFloat x0 = 0;
        CGFloat y0 = 0;
        
        float aspect = image.size.width / image.size.height;
        
        if (image.size.width > image.size.height) {
            scaledSize.width = newSize.width * aspect;
            scaledSize.height = newSize.height;
            x0 = -(scaledSize.width - newSize.width) / 2;
        } else {
            scaledSize.width = newSize.width;
            scaledSize.height = newSize.height / aspect;
            y0 = -(scaledSize.height - newSize.height) / 2;
        }
        [image drawInRect:CGRectMake(x0, y0, scaledSize.width, scaledSize.height )];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
    } UIGraphicsEndImageContext();

    _screenshot = newImage;
    _needsScreenshotUpdate = NO;

    // The screenshot is part of the document package. Mark it as a document
    // change so close/autosave persists it even when circuit data was already
    // autosaved before the screenshot was rendered.
    [super updateChangeCount:UIDocumentChangeDone];
}

- (void)updateChangeCount:(UIDocumentChangeKind)change {
    if (change == UIDocumentChangeDone ||
        change == UIDocumentChangeUndone ||
        change == UIDocumentChangeRedone) {
        _needsScreenshotUpdate = YES;
    }
    [super updateChangeCount:change];
}

- (NSArray *) exportItems {
    
    NSMutableArray *items = [NSMutableArray array];
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:object->type->numOutputs];
        for(int i = 0; i < object->type->numOutputs; i++) {
            NSMutableArray *linksFromOutlet = [NSMutableArray array];
            CircuitLink *link = object->outputs[i];
            while (link) {
                [linksFromOutlet addObject:@[[MongoID stringWithId:link->target->id], @(link->targetIndex)]];
                link = link->nextSibling;
            }
            [outputs addObject:linksFromOutlet];
        }
        
        NSString *name = nil;
        if (object->name[0] != '\0') {
            name = [NSString stringWithUTF8String:object->name];
        }
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        d[@"type"] = [NSString stringWithUTF8String:object->type->id];
        d[@"_id"]  = [MongoID stringWithId:object->id];
        d[@"pos"]  = @[@(object->pos.x), @(object->pos.y), @(object->pos.z)];
        d[@"name"] = name ?: @"";
        d[@"in"]   = @(object->in);
        d[@"out"]  = @(object->out);
        d[@"outputs"] = outputs;

        if (object->flags & CircuitObjectFlagLocked) {
            d[@"locked"] = @1;
        }
        
        
        [items addObject:d];
    }];
    return items;
}


- (NSDictionary *) exportPackageDictionaryWithoutItems {
    NSMutableArray *testsArray = [NSMutableArray arrayWithCapacity:_circuit.tests.count];
    [_circuit.tests enumerateObjectsUsingBlock:^(CircuitTest *test, NSUInteger idx, BOOL *stop) {
        // Bundled and hand-authored packages can omit per-test names and specs.
        NSMutableDictionary *testDictionary = [@{
                                                 @"name": test.name ?: @"",
                                                 @"inputs": test.inputIds,
                                                 @"outputs": test.outputIds,
                                                 @"spec": test.spec ?: @[]
                                                 } mutableCopy];
        if (test.acceptedSpecs.count) {
            testDictionary[@"acceptedSpecs"] = test.acceptedSpecs;
        }
        [testsArray addObject:testDictionary];
    }];
    
    NSMutableArray *notes = [NSMutableArray arrayWithCapacity:_circuit.notes.count];
    for (CircuitNote *note in _circuit.notes) {
        [notes addObject:note.dictionaryRepresentation];
    }

    // Every field here can be absent from an imported package; a nil value in
    // the literal would throw during autosave and lose the user's edits.
    return @{
        @"_id": [MongoID stringWithId:_circuit.id],
        @"name": _circuit.name ?: @"",
        @"version": _circuit.version ?: @"",
        @"description": _circuit.userDescription ?: @"",
        @"title": _circuit.title ?: @"",
        @"author": _circuit.author ?: @"",
        @"license": _circuit.license ?: @"",
        @"engines": @{@"circuitry": @">=0.0"},
        @"tests" : testsArray,
        @"notes": notes,
        @"view": _circuit.viewDetails ?: @{},
        @"meta": _circuit.meta ?: @{}
    };
    
}



- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    if (self.isProblem) {
        [NSException raise:@"Attempted to modify problem" format:@""];
    }
//    if (!_circuit) {
//        *outError = [NSError errorWithDomain:@"au.id.af" code:501 userInfo:@{@"name": @"Circuit does not exist"}];
//        return nil;
//    }
    if ([typeName isEqualToString:@"public.json"]) {
        NSMutableDictionary *dict = [[self exportPackageDictionaryWithoutItems] mutableCopy];
        dict[@"items"] = [self exportItems];
        // Export the entire circuit into a single JSON object:
        return [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    }
    
    NSJSONWritingOptions jsonOptions = 0;
    
#ifdef DEBUG
    jsonOptions = NSJSONWritingPrettyPrinted;
#endif

    NSDictionary<NSString *, NSFileWrapper *> *fileWrappers = [[NSDictionary alloc] init];
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers];
    NSData *metaJson = [NSJSONSerialization dataWithJSONObject:[self exportPackageDictionaryWithoutItems] options:jsonOptions error:NULL];
    NSData *itemsJSON = [NSJSONSerialization dataWithJSONObject:[self exportItems] options:jsonOptions error:NULL];

    [wrapper addRegularFileWithContents:metaJson preferredFilename:@"package.json"];
    [wrapper addRegularFileWithContents:itemsJSON preferredFilename:@"items.json"];
    if (_screenshot) {
        [wrapper addRegularFileWithContents:UIImagePNGRepresentation(_screenshot) preferredFilename:screenshotPngPath];
    } else if (_originalScreenshotData) {
        [wrapper addRegularFileWithContents:_originalScreenshotData preferredFilename:screenshotPngPath];
    }
    return wrapper;
}

- (NSUInteger)deleteObjectsWithIDs:(NSArray<NSString *> *)objectIDs {
    if (self.isProblem || !self.circuit || self.circuitEditInProgress) return 0;
    NSMutableArray<NSString *> *existingIDs = [NSMutableArray array];
    for (NSString *identifier in [NSOrderedSet orderedSetWithArray:objectIDs]) {
        CircuitObject *object = [self.circuit findObjectById:identifier];
        if (!object) continue;
        if (object->flags & CircuitObjectFlagLocked) return 0;
        [existingIDs addObject:identifier];
    }
    if (!existingIDs.count) return 0;
    [self beginCircuitEdit:@"Delete Selection"];
    [self.circuit performWriteBlock:^(CircuitInternal *internal) {
        for (NSString *identifier in existingIDs) {
            // Removing a component also removes its incoming and outgoing wires.
            CircuitObjectRemove(internal, [self.circuit findObjectById:identifier]);
        }
    }];
    [self finishCircuitEdit];
    return existingIDs.count;
}

// Snapshot IDs and values before allocating: growing the circuit can relocate objects.
- (NSArray<NSString *> *)duplicateObjectsWithIDs:(NSArray<NSString *> *)objectIDs offset:(CGVector)offset {
    if (self.isProblem || !self.circuit || !objectIDs.count) return @[];
    NSArray<NSString *> *uniqueIDs = [NSOrderedSet orderedSetWithArray:objectIDs].array;
    NSSet *selected = [NSSet setWithArray:uniqueIDs];
    NSMutableArray *objects = [NSMutableArray array];
    NSMutableArray *links = [NSMutableArray array];
    for (NSString *identifier in uniqueIDs) {
        CircuitObject *object = [self.circuit findObjectById:identifier];
        if (!object) continue;
        [objects addObject:@{@"id": identifier, @"type": [NSString stringWithUTF8String:object->type->id],
                             @"name": [NSString stringWithUTF8String:object->name] ?: @"",
                             @"x": @(object->pos.x), @"y": @(object->pos.y), @"z": @(object->pos.z),
                             @"out": @(object->out), @"data": @(object->data)}];
        for (int i = 0; i < object->type->numOutputs; i++) {
            for (CircuitLink *link = object->outputs[i]; link; link = link->nextSibling) {
                NSString *targetID = [MongoID stringWithId:link->target->id];
                if ([selected containsObject:targetID]) {
                    [links addObject:@{@"source": identifier, @"target": targetID,
                                       @"sourceIndex": @(i), @"targetIndex": @(link->targetIndex)}];
                }
            }
        }
    }
    if (!objects.count) return @[];
    [self beginCircuitEdit:@"Duplicate Selection"];
    NSMutableDictionary<NSString *, NSString *> *copies = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *newIDs = [NSMutableArray array];
    [self.circuit performWriteBlock:^(CircuitInternal *internal) {
        for (NSDictionary *saved in objects) {
            CircuitObject *copy = CircuitObjectCreate(internal, [self.circuit getProcessById:saved[@"type"]]);
            if (!copy) continue;
            copy->id = [MongoID id];
            copy->pos.x = [saved[@"x"] floatValue] + offset.dx;
            copy->pos.y = [saved[@"y"] floatValue] + offset.dy;
            copy->pos.z = [saved[@"z"] floatValue];
            copy->data = [saved[@"data"] unsignedIntValue];
            strlcpy(copy->name, [saved[@"name"] UTF8String], sizeof(copy->name));
            CircuitObjectSetOutput(internal, copy, [saved[@"out"] intValue]);
            NSString *newID = [MongoID stringWithId:copy->id];
            copies[saved[@"id"]] = newID;
            [newIDs addObject:newID];
        }
        for (NSDictionary *saved in links) {
            NSString *sourceID = copies[saved[@"source"]];
            NSString *targetID = copies[saved[@"target"]];
            if (!sourceID || !targetID) continue;
            CircuitLinkCreate(internal, [self.circuit findObjectById:sourceID], [saved[@"sourceIndex"] intValue],
                              [self.circuit findObjectById:targetID], [saved[@"targetIndex"] intValue]);
        }
    }];
    [self finishCircuitEdit];
    return newIDs;
}

@end
