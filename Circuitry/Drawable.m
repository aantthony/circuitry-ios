#import "Drawable.h"

@implementation Drawable

- (void) draw {
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"]; 
}

@end
