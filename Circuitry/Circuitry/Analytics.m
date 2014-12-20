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

+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [Mixpanel sharedInstanceWithToken: @"487f2144b76c05506336adaa68417724" launchOptions:launchOptions];
#else
    [Mixpanel sharedInstanceWithToken: @"c237d5808c43a7b6e615284dd3050afc" launchOptions:launchOptions];
#endif
    return YES;
}

- (Mixpanel *) mixpanel {
    return [Mixpanel sharedInstance];
}

@end
