#import "BatchedSprite.h"

@interface BatchedSprite() {
    BatchedSpriteInstance *_instances;
    GLKTextureInfo *_texture;
    GLuint _instanceBuffer;
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
        [ShaderEffect checkError];
        return;
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
        
        
        return;
    }
    
}

- (id) initWithTexture:(GLKTextureInfo *)texture capacity:(int) capacity {
    self = [super init];
    
    _texture = texture;
    
    _capacity = capacity;
    _instances = malloc(sizeof(BatchedSpriteInstance) * capacity);
    
    
    glGenBuffers(1, &_instanceBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _instanceBuffer);
    for(int i = 0; i < _capacity; i++) {
        _instances[i].x = _instances[i].y = 0.0;
        _instances[i].u = _instances[i].v = 0.0;
        _instances[i].width = 208.0;
        _instances[i].height = 104.0;
    }
    
    // TODO: pass NULL, not _instances!
    glBufferData(GL_ARRAY_BUFFER, sizeof(BatchedSpriteInstance) * _capacity, _instances, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(aSource);
    glEnableVertexAttribArray(aTranslate);
    
    return self;
}
- (BatchedSpriteInstance *) instances {
    return _instances;
}

- (void) drawWithTransform: (GLKMatrix4) viewProjectionMatrix {
    [shader prepareToDraw];

    [ShaderEffect checkError];
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    [ShaderEffect checkError];
    const GLvoid *indices = 0;
    GLsizei instanceCount = _capacity;
    
    [ShaderEffect checkError];
    
    int i = 0;
    // Use the texture @i
    glActiveTexture(GL_TEXTURE0 + i);
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    glUniform1i(uTexture, i);
    
    
    [ShaderEffect checkError];
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    
    [ShaderEffect checkError];
    //glVertexAttribDivisorEXT(GLKVertexAttribPosition, 6);
    //glVertexAttribDivisorEXT(GLKVertexAttribTexCoord0, 6);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SharedSpriteVertexData), (const GLvoid *) offsetof(SharedSpriteVertexData, texCoord0));
    
    glVertexAttribPointer(aTranslate, 2, GL_UNSIGNED_SHORT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, x));
    
    glVertexAttribPointer(aSource, 4, GL_UNSIGNED_SHORT, GL_FALSE, sizeof(BatchedSpriteInstance), (const GLvoid *) offsetof(BatchedSpriteInstance, u));
    
    [ShaderEffect checkError];
    glVertexAttribDivisorEXT(aSource, 1);
    glVertexAttribDivisorEXT(aTranslate, 1);

    glDrawElementsInstancedEXT(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices, instanceCount);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    
    glVertexAttribDivisorEXT(GLKVertexAttribPosition, 0);
    glVertexAttribDivisorEXT(GLKVertexAttribTexCoord0, 0);
    
    glVertexAttribDivisorEXT(aSource, 0);
    glVertexAttribDivisorEXT(aTranslate, 0);
    
    [ShaderEffect checkError];
}

@end
