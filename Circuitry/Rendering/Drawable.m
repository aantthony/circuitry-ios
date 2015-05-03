#import "Drawable.h"

@implementation Drawable

- (void) drawWithStack:(GLKMatrixStackRef) stack {
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"]; 
}

@end
