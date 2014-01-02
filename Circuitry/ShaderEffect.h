#import <GLKit/GLKit.h>

@interface ShaderEffect : NSObject <GLKNamedEffect>

@property (nonatomic, readonly)        GLKEffectPropertyTransform          *transform;                  // Identity Matrices
@property (nonatomic, readonly)        GLKEffectPropertyTexture            *texture2d0, *texture2d1;    // Disabled
@property (nonatomic, copy)            NSArray                             *textureOrder;               // texture2d0, texture2d1
@property (nonatomic, copy)            NSString                            *label;                      // nil

-(ShaderEffect *) initWithVertexSource: (NSString *)vertShaderPathname withFragmentSource:(NSString *)fragShaderPathname withUniforms:(NSDictionary *)uniforms withAttributes:(NSDictionary *)attributes;

- (GLint) getUniformLocation:(NSString *) name;

//- (GLKEffectProperty *) getFloatProperty:(NSString *) name;

@end
