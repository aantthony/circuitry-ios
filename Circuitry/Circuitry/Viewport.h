#import <GLKit/GLKit.h>

#import "Drawable.h"
#import "Circuit.h"
#import "ImageAtlas.h"

@interface Viewport : Drawable

- (id) initWithContext: (EAGLContext*) context atlas:(ImageAtlas *)atlas;
- (void) update: (NSTimeInterval) dt;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (void) setScale: (float) scale;
- (float) scale;

- (int) findInletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (GLKVector3) unproject: (CGPoint) screenPos;


- (void) setCircuit:(Circuit *) circuit;
- (Circuit *) circuit;

@property CircuitLink *currentEditingLink;
@property CircuitObject *currentEditingLinkSource;
@property CircuitObject *currentEditingLinkTarget;
@property int currentEditingLinkSourceIndex;
@property int currentEditingLinkTargetIndex;
@property GLKVector3 currentEditingLinkTargetPosition;

@end
