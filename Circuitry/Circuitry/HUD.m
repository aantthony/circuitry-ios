//
//  HUD.m
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "HUD.h"
#import "Toolbelt.h"

@interface HUD() {
    Viewport *_viewport;
}
@end

@implementation HUD

- (id) initWithAtlas:(ImageAtlas *)atlas {
    self = [super init];

    _toolbelt = [[Toolbelt alloc] initWithAtlas:atlas];
    return self;
}

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    GLKMatrixStackPush(stack);
    float devicePixelRatio = 2.0;
    GLKMatrixStackScale(stack,  1/ devicePixelRatio, 1/devicePixelRatio, 1/devicePixelRatio);
    [_toolbelt drawWithStack:stack];
    GLKMatrixStackPop(stack);
}
- (int) update: (NSTimeInterval) dt {
    return [_toolbelt update:dt];
}


- (void) setViewPort:(Viewport *)viewport {
    _viewport = viewport;
    _toolbelt.viewport = viewport;
}
@end
