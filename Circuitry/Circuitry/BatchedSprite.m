#import "BatchedSprite.h"

@interface BatchedSprite() {
    GLKTextureInfo *_texture;
    GLuint _instanceBuffer;
    
    float _tWidth, _tHeight;
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

static const GLushort batchedSpriteIndices[] = {
    0, 1, 2,
    2, 3, 0
};

// uniform locations:
static GLint uTexture;
static GLint uModelViewProjectMatrix;
static GLint uTextureSize;

// attribute locations:
static GLint aSource;
static GLint aTranslate;

// buffer names:
static GLuint _vertexBuffer;
static GLuint _indexBuffer;

static ShaderEffect *shader;
static GLint uModelViewProjectMatrix;

+ (void)setContext: (EAGLContext*) context {
    if (!shader) {
        
        NSDictionary *uniforms = @{@"opacity": @1.0};
        NSDictionary *attributes = @{
                                     @"aTranslate": @{},
                                     @"aSource": @{}
                                     };
        
        NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"BatchedSprite" ofType:@"vsh"];
        NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"BatchedSprite" ofType:@"fsh"];
        
        // compile shader program:
        shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:uniforms withAttributes:attributes];

        [ShaderEffect checkError];
        // uniform locations:
        uModelViewProjectMatrix = [shader getUniformLocation:@"modelViewProjectionMatrix"];
        uTexture                = [shader getUniformLocation:@"texture"];
        uTextureSize            = [shader getUniformLocation:@"textureSize"];
        
        [ShaderEffect checkError];

        aSource = [shader getAttributeLocation:@"source"];
        [ShaderEffect checkError];


        aTranslate = [shader getAttributeLocation:@"translate"];
//        [ShaderEffect checkError];

        glGenBuffers(1, &_indexBuffer);
        glGenBuffers(1, &_vertexBuffer);
        
        glEnableVertexAttribArray(aSource);
        glEnableVertexAttribArray(aTranslate);
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(batchedSpriteVertices), batchedSpriteVertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(batchedSpriteIndices), batchedSpriteIndices, GL_STATIC_DRAW);
        
        glDisableVertexAttribArray(aSource);
        glDisableVertexAttribArray(aTranslate);
        
    }
    
}

- (id) initWithTexture:(GLKTextureInfo *)texture capacity:(int) capacity {
    self = [super init];
    
    _texture = texture;
    
    glGenBuffers(1, &_instanceBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _instanceBuffer);
    glBufferData(GL_ARRAY_BUFFER, capacity * sizeof(BatchedSpriteInstance), NULL, GL_STATIC_DRAW);
    _tWidth = texture.width;
    _tHeight = texture.height;
    return self;
}

- (void) buffer:(const GLvoid *)data FromIndex:(int)start count:(int)count {
    glBindBuffer(GL_ARRAY_BUFFER, _instanceBuffer);
    
    [ShaderEffect checkError];
    size_t offset = start * sizeof(BatchedSpriteInstance);
    glBufferSubData(GL_ARRAY_BUFFER, offset, count * sizeof(BatchedSpriteInstance), data);
    [ShaderEffect checkError];
}

- (void) drawIndices:(int)start count:(int)count WithTransform: (GLKMatrix4) viewProjectionMatrix {
    [shader prepareToDraw];

    [ShaderEffect checkError];
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glEnableVertexAttribArray(aSource);
    glEnableVertexAttribArray(aTranslate);
    
    [ShaderEffect checkError];
    
    int i = 0;
    // Use the texture @i
    glActiveTexture(GL_TEXTURE0 + i);
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    glUniform1i(uTexture, i);
    
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    [ShaderEffect checkError];
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    
    glUniform2f(uTextureSize, _tWidth, _tHeight);
    
    [ShaderEffect checkError];
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, texCoord0));
    
    
    glBindBuffer(GL_ARRAY_BUFFER, _instanceBuffer);
    
    glVertexAttribPointer(aTranslate, 2, GL_FLOAT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, x));
    
    glVertexAttribPointer(aSource, 4, GL_FLOAT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, tex.x));
    
    [ShaderEffect checkError];
    glVertexAttribDivisorEXT(aSource, 1);
    glVertexAttribDivisorEXT(aTranslate, 1);

    //glDrawElements(GL_LINE_STRIP, 6, GL_UNSIGNED_SHORT, 0);
    
    glDrawElementsInstancedEXT(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0, count);
    
    glVertexAttribDivisorEXT(aSource, 0);
    glVertexAttribDivisorEXT(aTranslate, 0);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    glDisableVertexAttribArray(aSource);
    glDisableVertexAttribArray(aTranslate);
    
    
    [ShaderEffect checkError];
}

@end
