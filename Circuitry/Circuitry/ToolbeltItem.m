//
//  ToolbeltItem.m
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ToolbeltItem.h"

@implementation ToolbeltItem

- (instancetype) initWithType:(NSString *)type image:(UIImage *)image name:(NSString *)name subtitle:(NSString *)subtitle {
    self = [super init];
    
    _type     = type;
    _image    = image;
    _name     = name;
    _subtitle = subtitle;
    
    return self;
}
@end
