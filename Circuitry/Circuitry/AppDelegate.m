#import "AppDelegate.h"

#import <AFNetworking/AFNetworking.h>
//#import <AFNetworking/AFHTTPSessionManager.h>
#import "SocketClient.h"

@interface AppDelegate()
@property SocketClient *client;
@end
@implementation AppDelegate

+ (NSDictionary *) sharedConfiguration
{
    static dispatch_once_t onceToken = 0;
    static NSDictionary *config;
    
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *environment = [[bundle infoDictionary] objectForKey:@"Configuration"];
        config = [[NSDictionary dictionaryWithContentsOfFile:[bundle pathForResource:@"Configurations" ofType:@"plist"]] objectForKey:environment];
    });
    
    return config;
}


+ (AFHTTPRequestOperationManager *) api {
    static dispatch_once_t onceToken = 0;
    static AFHTTPRequestOperationManager * manager;
    
    dispatch_once(&onceToken, ^{
        manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL: [AppDelegate baseURL]];
    });
    
    return manager;
}

+ (NSURL *) baseURL {
    return [NSURL URLWithString:[[AppDelegate sharedConfiguration] objectForKey:@"APIEndpoint"]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _client = [SocketClient sharedInstance];
    
    [_client sendEvent:@"subscribe" withData:@"52d4f829c9aaf03423c13697" andAcknowledge:^(id err, id response) {
        NSLog(@"ready");
    }];
    
    [AppDelegate.api GET:@"debug" parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *res) {
        NSLog(@"JSON: %@", res);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
    }];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url scheme] isEqualToString:@"circuitry"]) {
        NSLog(@"Open: %@", url);
        return YES;
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
