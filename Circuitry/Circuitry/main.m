#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "QTouchposeApplication.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        NSString *principalClassName = NSStringFromClass([QTouchposeApplication class]);
        return UIApplicationMain(argc, argv, principalClassName, NSStringFromClass([AppDelegate class]));
    }
}
