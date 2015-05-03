#import "Sprite.h"
#import "ShaderEffect.h"

#import <OpenGLES/ES2/glext.h> 

@interface Sprite()
@property (nonatomic) GLKTextureInfo *texture;
@end

@implementation Sprite


typedef struct {
    float Position[3];
    float TexCoord1[2];
} Vertex;


static ShaderEffect *shader;

// uniform locations:
static GLint uTexture;
static GLint uModelViewProjectMatrix;
static GLint uSize;
static GLint uPos;

// buffer names:
static GLuint _quadVertexBuffer;
static GLuint _quadIndexBuffer;

static Vertex QuadVertices[] = {
    {{1, 0, 0}, {1, 0}},
    {{1, 1, 0}, {1, 1}},
    {{0, 1, 0}, {0, 1}},
    {{0, 0, 0}, {0, 0}}
};

static const GLushort QuadIndices[] = {
    0, 1, 2,
    2, 3, 0
};


static GLuint _vertexArray;

+ (void)setContext: (EAGLContext*) context {
    if (!shader) {
        
        NSDictionary *uniforms = @{@"opacity": @1.0};
        
        NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"Sprite" ofType:@"vsh"];
        NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"Sprite" ofType:@"fsh"];
        
        // compile shader program:
        shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:uniforms withAttributes:@{}];
        
        // uniform locations:
        uModelViewProjectMatrix = [shader uniformLocation:@"modelViewProjectionMatrix"];
        uTexture                = [shader uniformLocation:@"texture"];
        uSize                   = [shader uniformLocation:@"size"];
        uPos                    = [shader uniformLocation:@"pos"];
        
//        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        
        glGenBuffers(1, &_quadIndexBuffer);
        glGenBuffers(1, &_quadVertexBuffer);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        
        glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(QuadVertices), QuadVertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(QuadIndices), QuadIndices, GL_STATIC_DRAW);
        
//        glBindVertexArrayOES(0);
        
    }
    
}
+ (GLKTextureInfo *) textureWithContentsOfURL: (NSURL *) url {
    NSError* error = nil;
    
    int mipmap_levels = 0;
   
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool: mipmap_levels > 0], GLKTextureLoaderGenerateMipmaps,
                            [NSNumber numberWithBool:NO], GLKTextureLoaderApplyPremultiplication,
                             nil
                             ];

    GLKTextureInfo* info = [GLKTextureLoader textureWithContentsOfURL:url options:options error: &error];

    if (error) {
        [[NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:@{}] raise];
    }
    return info;
}

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture atX: (int) x Y:(int) y width:(int)w height: (int) h {
    
    // check sizes:
    if (x < 0 || y < 0 || w > texture.width || h > texture.height) return nil;
    
    // TODO: set position, size etc.
    
    _texture = texture;
    
    return self;
}

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture {
    return [self initWithTexture:texture atX:0 Y:0 width:texture.width height:texture.height];
}

- (void) drawWithSize: (GLKVector2) size withTransform:(GLKMatrix4) modelViewProjectionMatrix {
    return [self drawAtPoint:GLKVector3Make(0.0, 0.0, 0.0) withSize: size withTransform:modelViewProjectionMatrix];
}
- (void) drawAtPoint: (GLKVector3) pos withTransform:(GLKMatrix4) modelViewProjectionMatrix {
    return [self drawAtPoint:pos withSize:GLKVector2Make(_texture.width / 2, _texture.height / 2) withTransform:modelViewProjectionMatrix];
}
- (void) drawWithTransform: (GLKMatrix4) modelViewProjectionMatrix {
    return [self drawAtPoint:GLKVector3Make(0.0, 0.0, 0.0) withTransform:modelViewProjectionMatrix];
}
- (void) drawAtPoint: (GLKVector3) pos withSize: (GLKVector2) size withTransform:(GLKMatrix4) viewProjectionMatrix {
    // use program
    [shader prepareToDraw];
    // TODO: maybe this should be part of ShaderEffect, but I can't find any documenation for glBindVertexArrayOES so for now it is here:
//    glBindVertexArrayOES(_vertexArray);
    glEnable(GL_BLEND);
//    glEnable(GL_ALPHA_BITS);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    
    int i = 0;
    // Use the texture @i
    glActiveTexture(GL_TEXTURE0 + i);
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    glUniform1i(uTexture, i);
    
    GLKVector4 _color = {1.0, 1.0, 1.0, 1.0};
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord1));
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    glUniform2f(uSize, size.x, size.y);
    glUniform3f(uPos,  pos.x,  pos.y, 0.0);
    glVertexAttrib4fv(GLKVertexAttribColor, _color.v);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}


@end
