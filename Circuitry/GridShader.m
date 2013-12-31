//
//  GridShader.m
//  Circuitry
//
//  Created by Anthony Foster on 17/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import "GridShader.h"

@implementation GridShader
- (id) init {
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"Grid" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"Grid" ofType:@"fsh"];
    
    self = [super initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:nil withAttributes:nil];
    
    return self;
}
@end
