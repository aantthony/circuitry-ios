#import <GLKit/GLKit.h>

#import "Drawable.h"
#import "Circuit.h"
#import "ImageAtlas.h"

@interface Viewport : Drawable

@property Circuit *circuit;

- (id) initWithContext: (EAGLContext*) context atlas:(ImageAtlas *)atlas;
- (void)update;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (void) setScale: (float) scale;
- (float) scale;

- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (GLKVector3) unproject: (CGPoint) screenPos;


@property CircuitLink *currentEditingLink;
@property CircuitObject *currentEditingLinkSource;
@property CircuitObject *currentEditingLinkTarget;
@property int currentEditingLinkSourceIndex;
@property int currentEditingLinkTargetIndex;
@property GLKVector3 currentEditingLinkTargetPosition;

@end
