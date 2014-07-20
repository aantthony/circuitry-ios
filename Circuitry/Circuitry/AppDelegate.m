#import "AppDelegate.h"

#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import <GoogleAnalytics-iOS-SDK/GAIFields.h>
#import <GoogleAnalytics-iOS-SDK/GAIDictionaryBuilder.h>

@interface AppDelegate()
@end
@implementation AppDelegate

- (id <GAITracker>) tracker {
    return [[GAI sharedInstance] trackerWithTrackingId:@"UA-48110067-1"];
}
+ (AppDelegate *) sharedDelegate {
    return [[UIApplication sharedApplication] delegate];
}

+ (void) trackView:(NSString *)screenName {
    // instead of using Google's bloated UIViewController subclass, just set the screen name, 
    id <GAITracker> tracker = self.sharedDelegate.tracker;
    
    // This screen name value will remain set on the tracker and sent with
    // hits until it is set to a new value or to nil.
    [tracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    GAI *g = [GAI sharedInstance];
    
    g.trackUncaughtExceptions = YES;
    g.dispatchInterval = 20;
    g.dryRun = YES;
    g.logger.logLevel = kGAILogLevelWarning;
    
    id<GAITracker> tracker = self.tracker;
    
    NSLog(@"Google analytics tracker: %@", tracker.name);
    
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

+ (NSURL *) documentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
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
