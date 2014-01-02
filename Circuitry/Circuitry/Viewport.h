#import "Drawable.h"

#import "Grid.h"
#import "Sprite.h"
#import "Circuit.h"

@interface Viewport : Drawable

@property GLKMatrix4 modelViewProjectionMatrix;
@property Circuit *circuit;

- (id) initWithContext: (EAGLContext*) context;
- (void)update;

@end
