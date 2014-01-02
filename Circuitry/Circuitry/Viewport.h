#import <GLKit/GLKit.h>

#import "Drawable.h"
#import "Circuit.h"

@interface Viewport : Drawable

@property Circuit *circuit;

- (id) initWithContext: (EAGLContext*) context;
- (void)update;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (void) setScale: (float) scale;
- (float) scale;

- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (GLKVector3) unproject: (CGPoint) screenPos;
@end
