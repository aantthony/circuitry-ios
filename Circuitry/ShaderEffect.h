// TODO: Open source this on github

#import <GLKit/GLKit.h>

typedef GLint GLUniformLocation;
typedef GLint GLAttributeLocation;

@interface ShaderEffect : NSObject <GLKNamedEffect>

@property (nonatomic, readonly)        GLKEffectPropertyTransform          *transform;                  // Identity Matrices
@property (nonatomic, readonly)        GLKEffectPropertyTexture            *texture2d0, *texture2d1;    // Disabled
@property (nonatomic, copy)            NSArray                             *textureOrder;               // texture2d0, texture2d1
@property (nonatomic, copy)            NSString                            *label;                      // nil

-(ShaderEffect *) initWithVertexSource: (NSString *)vertShaderPathname withFragmentSource:(NSString *)fragShaderPathname withUniforms:(NSDictionary *)uniforms withAttributes:(NSDictionary *)attributes;

+ (void) checkError;

- (GLUniformLocation)   uniformLocation  :(NSString *) name;
- (GLAttributeLocation) attributeLocation:(NSString *) name;

//- (GLKEffectProperty *) getFloatProperty:(NSString *) name;

@end
