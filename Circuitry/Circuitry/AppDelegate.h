#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSURL *) documentsDirectory;
+ (void) trackView:(NSString *)screenName;

@end
