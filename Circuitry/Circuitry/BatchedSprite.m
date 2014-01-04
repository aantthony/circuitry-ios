#import "BatchedSprite.h"

@interface BatchedSprite() {
    BatchedSpriteInstance *_instances;
    GLKTextureInfo *_texture;
}

@end

@implementation BatchedSprite


typedef struct {
    float position[3];
    float texCoord0[2];
} SharedSpriteVertexData;

static SharedSpriteVertexData batchedSpriteVertices[] = {
    {{1, 0, 0}, {1, 0}},
    {{1, 1, 0}, {1, 1}},
    {{0, 1, 0}, {0, 1}},
    {{0, 0, 0}, {0, 0}}
};

const GLushort batchedSpriteIndices[] = {
    0, 1, 2,
    2, 3, 0
};

// uniform locations:
GLint uTexture;
GLint uModelViewProjectMatrix;

// attribute locations:
GLint aSource;
GLint aTranslate;

// buffer names:
GLuint _vertexBuffer;
GLuint _indexBuffer;

ShaderEffect *shader;
GLint uModelViewProjectMatrix;

+ (void)setContext: (EAGLContext*) context {

    if (!shader) {
        
        NSDictionary *uniforms = @{@"opacity": @1.0};
        NSDictionary *attributes = @{
                                     @"aTranslate": @{},
                                     @"aSource": @{}
                                     };
        
        NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"Sprite" ofType:@"vsh"];
        NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"Sprite" ofType:@"fsh"];
        
        // compile shader program:
        shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:uniforms withAttributes:attributes];
        
        // uniform locations:
        uModelViewProjectMatrix = [shader getUniformLocation:@"modelViewProjectionMatrix"];
        uTexture                = [shader getUniformLocation:@"texture"];
        aSource = [shader getAttributeLocation:@"source"];
        aTranslate = [shader getAttributeLocation:@"translate"];
        
        glGenBuffers(1, &_indexBuffer);
        glGenBuffers(1, &_vertexBuffer);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(batchedSpriteVertices), batchedSpriteVertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(batchedSpriteIndices), batchedSpriteIndices, GL_STATIC_DRAW);
        
        
    }
    
}

- (id) initWithTexdture:(GLKTextureInfo *)texture capacity:(int) capacity {
    self = [super init];
    
    _texture = texture;
    
    _capacity = capacity;
    _instances = malloc(sizeof(BatchedSpriteInstance) * capacity);
    
    return self;
}
- (BatchedSpriteInstance *) instances {
    return _instances;
}

- (void) drawWithTransform: (GLKMatrix4) viewProjectionMatrix {
    [shader prepareToDraw];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    const GLvoid *indices = 0;
    GLsizei instanceCount = _capacity;
    
    glUniform1f(uTexture, _texture.name);
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    
    glVertexAttribDivisorEXT(GLKVertexAttribPosition, 6);
    glVertexAttribDivisorEXT(GLKVertexAttribTexCoord0, 6);
    
    glVertexAttribDivisorEXT(aSource, 1);
    glVertexAttribDivisorEXT(aTranslate, 1);
    
    glDrawElementsInstancedEXT(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices, instanceCount);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}

@end
