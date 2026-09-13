//
//  CircuitDocument.h
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "Circuit.h"
@class ProblemSetProblemInfo;
extern NSString * const CircuitDocumentHistoryDidChangeNotification;
extern NSString * const CircuitDocumentCircuitDidRestoreNotification;

@interface CircuitDocument : UIDocument
@property (nonatomic) Circuit *circuit;
@property (nonatomic, readonly) BOOL isProblem;
@property (nonatomic) ProblemSetProblemInfo *problemInfo;
@property (nonatomic, readonly) UIImage *screenshot;
@property (nonatomic, readonly) BOOL needsScreenshotUpdate;
@property (nonatomic, readonly) NSError *loadError;
- (NSArray<NSString *> *)duplicateObjectsWithIDs:(NSArray<NSString *> *)objectIDs offset:(CGVector)offset;
- (NSUInteger)deleteObjectsWithIDs:(NSArray<NSString *> *)objectIDs;
// Explicit transactions group an entire drag or compound edit into one undo step.
@property (nonatomic, readonly) NSUndoManager *editorUndoManager;
@property (nonatomic, readonly) BOOL circuitEditInProgress;
- (void)beginCircuitEdit:(NSString *)actionName;
- (void)finishCircuitEdit;

- (void) useScreenshot:(UIImage *)image;
@end
