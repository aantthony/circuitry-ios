#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Drawable : NSObject
- (void) drawWithStack:(GLKMatrixStackRef) stack;

@end
