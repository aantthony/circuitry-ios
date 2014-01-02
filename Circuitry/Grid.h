#import <GLKit/GLKit.h>
#import "Drawable.h"

@interface Grid : Drawable
@property GLKMatrix4 viewProjectionMatrix;
- (void) setScale: (GLKVector3) scale translate:(GLKVector3) translate;
@end
