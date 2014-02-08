#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSDictionary *) sharedConfiguration;
+ (NSURL *) baseURL;
+ (AFHTTPRequestOperationManager *) api;

+ (NSURL *) documentsDirectory;

@end
