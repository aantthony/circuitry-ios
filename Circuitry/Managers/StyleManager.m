//
//  StyleManager.m
//  Circuitry
//
//  Created by Anthony Foster on 20/12/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "StyleManager.h"

@implementation StyleManager

+ (instancetype) shared {
    static id shared = nil;
    if (!shared) shared = [self new];
    return shared;
}

+ (UIColor *) rgb:(NSInteger) color {
    NSInteger blue  = color % 0x100;
    color >>= 8;
    NSInteger green = color % 0x100;
    color >>= 8;
    NSInteger red   = color % 0x100;
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UINavigationBar *prototype = [UINavigationBar appearance];
    prototype.tintColor = [UIColor whiteColor];
    prototype.barTintColor = [StyleManager rgb:0x122639];
    prototype.titleTextAttributes = @{
        NSForegroundColorAttributeName:[UIColor whiteColor]
    };
    return YES;
}
@end
