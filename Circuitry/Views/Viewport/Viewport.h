#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include <math.h>

#import "CircuitInternal.h"
#import "ImageAtlas.h"
@class CircuitDocument;
@class CircuitNote;
@class SKScene;

@interface Viewport : NSObject


- (id) initWithAtlas:(ImageAtlas *)atlas;
- (int) update: (NSTimeInterval) dt;

- (void) didDetachEditingLink;
- (void) didAttachLink:(CircuitLink *)link;
- (void) didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;
- (void) drawInRect:(CGRect)rect;

// GPU-backed editor rendering. Core Graphics drawing remains available for
// document thumbnails and snapshots.
- (void) attachToScene:(SKScene *)scene backgroundImage:(UIImage *)backgroundImage;
- (void) setSceneContentNeedsUpdate;
- (void) updateSceneForViewSize:(CGSize)viewSize allowContentRebuild:(BOOL)allowContentRebuild;

- (void) setScaleWithFloat: (float) scale;
- (float) scaleWithFloat;

- (int) findOutletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (int) findInletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (CircuitObject*) findCircuitObjectNearPosition: (GLKVector3) pos;
- (CircuitNote *) findNoteAtPosition:(GLKVector3)pos;
- (CircuitNote *) findNoteResizeHandleAtPosition:(GLKVector3)pos;
- (CGRect) resizeHandleRectForNote:(CircuitNote *)note;
- (CGRect) rectForObject:(CircuitObject *) object inView:(UIView *)view;
- (CGRect) rectForNote:(CircuitNote *)note inView:(UIView *)view;

- (GLKVector3) unproject: (CGPoint) screenPos;

@property (nonatomic) CircuitDocument *document;
@property (nonatomic) CircuitLink *currentEditingLink;
@property (nonatomic) CircuitObject *currentEditingLinkSource;
@property (nonatomic) CircuitObject *currentEditingLinkTarget;
@property (nonatomic) int currentEditingLinkSourceIndex;
@property (nonatomic) int currentEditingLinkTargetIndex;
@property (nonatomic) GLKVector3 currentEditingLinkTargetPosition;

@property (nonatomic) GLKVector3 translate;
@property (nonatomic) GLKVector3 scale;

@end
