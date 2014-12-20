//
//  Analytics.m
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "Analytics.h"
#import <Mixpanel/Mixpanel.h>

@implementation Analytics

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *token = @"c237d5808c43a7b6e615284dd3050afc";

#ifdef DEBUG
    token = @"487f2144b76c05506336adaa68417724";
#endif
    
    [Mixpanel sharedInstanceWithToken:token launchOptions:launchOptions];
    [self configure];
    return YES;
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self.mixpanel.people addPushDeviceToken:deviceToken];
}

- (Mixpanel *) mixpanel {
    return [Mixpanel sharedInstance];
}

+ (instancetype) shared {
    static id shared = nil;
    if (!shared) shared = [self new];
    return shared;
}

- (void) configure {
    NSMutableDictionary *properties = [NSMutableDictionary new];
    [self.mixpanel identify:self.mixpanel.distinctId];
//    [self.mixpanel.people set:@{}];
    [self.mixpanel registerSuperProperties:properties];
}

- (void) track:(NSString *) event properties:(NSDictionary *)properties {
    [self.mixpanel track:event properties:properties];
}

@end
