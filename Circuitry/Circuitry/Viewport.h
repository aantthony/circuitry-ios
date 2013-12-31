#import "Drawable.h"

#import "Grid.h"
#import "Sprite.h"

@interface Viewport : Drawable

@property GLKMatrix4 modelViewProjectionMatrix;

- (id) initWithContext: (EAGLContext*) context;

@end
