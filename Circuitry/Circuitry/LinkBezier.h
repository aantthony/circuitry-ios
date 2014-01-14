#import <GLKit/GLKit.h>
@interface LinkBezier : NSObject
- (id) init;
- (void) drawFrom: (GLKVector2) A to: (GLKVector2) B withColor1:(GLKVector3)color1 color2: (GLKVector3) color2 active:(BOOL)isActive withTransform:(GLKMatrix4) viewProjectionMatrix;
@end
