#import <GLKit/GLKit.h>

#import "Drawable.h"
#import "CircuitInternal.h"
#import "ImageAtlas.h"
@class CircuitDocument;

@interface Viewport : Drawable

- (id) initWithContext: (EAGLContext*) context atlas:(ImageAtlas *)atlas;
- (int) update: (NSTimeInterval) dt;

- (void) didDetachEditingLink;
- (void) didAttachLink:(CircuitLink *)link;
- (void) didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (void) setScaleWithFloat: (float) scale;
- (float) scaleWithFloat;

- (int) findOutletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (int) findInletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (CGRect) rectForObject:(CircuitObject *) object inView:(UIView *)view;

- (GLKVector3) unproject: (CGPoint) screenPos;

@property (nonatomic) CircuitDocument *document;
@property (nonatomic) CircuitLink *currentEditingLink;
@property (nonatomic) CircuitObject *currentEditingLinkSource;
@property (nonatomic) CircuitObject *currentEditingLinkTarget;
@property (nonatomic) int currentEditingLinkSourceIndex;
@property (nonatomic) int currentEditingLinkTargetIndex;
@property (nonatomic) GLKVector3 currentEditingLinkTargetPosition;

@end
