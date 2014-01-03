#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSDictionary *) sharedConfiguration;

+ (AFHTTPRequestOperationManager *) api;

@end
