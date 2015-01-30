#import "BatchedSprite.h"

#import <OpenGLES/ES2/glext.h> 

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
static GLuint aSource;
static GLuint aTarget;

// buffer names:
static GLuint _vertexBuffer;
static GLuint _indexBuffer;

static ShaderEffect *shader;
static GLint uModelViewProjectMatrix;

+ (void)setContext: (EAGLContext*) context {
    if (!shader) {
        NSDictionary *uniforms = @{@"opacity": @1.0};
        NSDictionary *attributes = @{
                                     @"aTarget": @{},
                                     @"aSource": @{}
                                     };
        
        NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"BatchedSprite" ofType:@"vsh"];
        NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"BatchedSprite" ofType:@"fsh"];
        
        // compile shader program:
        shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:uniforms withAttributes:attributes];

        [ShaderEffect checkError];
        // uniform locations:
        uModelViewProjectMatrix = [shader uniformLocation:@"modelViewProjectionMatrix"];
        uTexture                = [shader uniformLocation:@"texture"];
        uTextureSize            = [shader uniformLocation:@"textureSize"];
        
        [ShaderEffect checkError];

        aSource = [shader attributeLocation:@"source"];
        [ShaderEffect checkError];


        aTarget = [shader attributeLocation:@"target"];
        [ShaderEffect checkError];

        glGenBuffers(1, &_indexBuffer);
        glGenBuffers(1, &_vertexBuffer);
        [ShaderEffect checkError];
        glEnableVertexAttribArray(aSource);
        [ShaderEffect checkError];
        glEnableVertexAttribArray(aTarget);
        [ShaderEffect checkError];
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        [ShaderEffect checkError];
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(batchedSpriteVertices), batchedSpriteVertices, GL_STATIC_DRAW);
        [ShaderEffect checkError];
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        [ShaderEffect checkError];
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(batchedSpriteIndices), batchedSpriteIndices, GL_STATIC_DRAW);
        [ShaderEffect checkError];
        glDisableVertexAttribArray(aSource);
        glDisableVertexAttribArray(aTarget);
        [ShaderEffect checkError];
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
    glEnableVertexAttribArray(aTarget);
    
    [ShaderEffect checkError];
    
    int i = 0;
    // Use the texture @i
    glActiveTexture(GL_TEXTURE0 + i);
    
    [ShaderEffect checkError];
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    
    [ShaderEffect checkError];
    glUniform1i(uTexture, i);
    
    [ShaderEffect checkError];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    [ShaderEffect checkError];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    [ShaderEffect checkError];
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    [ShaderEffect checkError];
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    
    glUniform2f(uTextureSize, _tWidth, _tHeight);
    
    [ShaderEffect checkError];
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, texCoord0));
    
    
    glBindBuffer(GL_ARRAY_BUFFER, _instanceBuffer);
    
    glVertexAttribPointer(aTarget, 4, GL_FLOAT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, x));
    glVertexAttribPointer(aSource, 4, GL_FLOAT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, tex.u));
    
    [ShaderEffect checkError];
    glVertexAttribDivisorEXT(aSource, 1);
    glVertexAttribDivisorEXT(aTarget, 1);

    //glDrawElements(GL_LINE_STRIP, 6, GL_UNSIGNED_SHORT, 0);
    
    glDrawElementsInstancedEXT(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0, count);
    
    glVertexAttribDivisorEXT(aSource, 0);
    glVertexAttribDivisorEXT(aTarget, 0);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    glDisableVertexAttribArray(aSource);
    glDisableVertexAttribArray(aTarget);
    
    
    [ShaderEffect checkError];
}

@end
