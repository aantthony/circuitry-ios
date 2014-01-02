#import "Drawable.h"

#import "Grid.h"
#import "Sprite.h"
#import "Circuit.h"

@interface Viewport : Drawable

@property Circuit *circuit;

- (id) initWithContext: (EAGLContext*) context;
- (void)update;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (void) setScale: (float) scale;
- (float) scale;


- (CircuitObject*) findCircuitObjectAtPosition: (CGPoint) pos;

@end
