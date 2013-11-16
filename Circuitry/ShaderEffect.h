//
//  ShaderEffect.h
//  Circuitry
//
//  Created by Anthony Foster on 16/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface ShaderEffect : NSObject <GLKNamedEffect>

-(ShaderEffect *) initWithVertexSource: (NSString *)vertShaderPathname withFragmentSource:(NSString *)fragShaderPathname withUniforms:(NSDictionary *)uniforms withAttributes:(NSDictionary *)attributes;

- (void) setUniform:(NSString *) name withValue:(id) value;

@end
