//
//  Analytics.h
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analytics : NSObject

+ (instancetype) shared;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void) track:(NSString *) event properties:(NSDictionary *)properties;
@end
