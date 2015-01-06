//
//  HUD.m
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "HUD.h"

@interface HUD()
@end

@implementation HUD

- (id) initWithAtlas:(ImageAtlas *)atlas {
    self = [super init];
    return self;
}

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    GLKMatrixStackPush(stack);
    float devicePixelRatio = 2.0;
    GLKMatrixStackScale(stack,  1/ devicePixelRatio, 1/devicePixelRatio, 1/devicePixelRatio);
    GLKMatrixStackPop(stack);
}
- (int) update: (NSTimeInterval) dt {
    return 0;
}

@end
