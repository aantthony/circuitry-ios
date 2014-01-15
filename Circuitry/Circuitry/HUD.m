//
//  HUD.m
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "HUD.h"
#import "Toolbelt.h"

@interface HUD() {}

@end

@implementation HUD

- (id) initWithAtlas:(ImageAtlas *)atlas {
    self = [super init];

    _toolbelt = [[Toolbelt alloc] initWithAtlas:atlas];
    return self;
}

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    [_toolbelt drawWithStack:stack];
}

@end
