//
//  StyleManager.h
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StyleManager : NSObject
+ (instancetype) shared;
+ (UIColor *) rgb:(NSInteger) color;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
@end
