//
//  SevenSegmentDisplay.m
//  Circuitry
//
//  Created by Anthony Foster on 1/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "SevenSegmentDisplay.h"
#import "ShaderEffect.h"

@interface SevenSegmentDisplay() {
    GLUniformLocation uModelViewProjectMatrix;
    GLUniformLocation uPos;
    GLUniformLocation uSize;
    GLUniformLocation uSource;
    GLUniformLocation uData;
    
    GLUniformLocation uTexture;
    
    GLuint _quadVertexBuffer;
    GLuint _quadIndexBuffer;
    
    GLKTextureInfo *_texture;
    
    SpriteTexturePos _source;
}
@property (nonatomic) ShaderEffect *shader;
@end
@implementation SevenSegmentDisplay



typedef struct {
    float Position[3];
    float TexCoord1[2];
} Vertex;


- (id) init {
    self = [super init];
    
    
    
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"SevenSegmentDisplay" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"SevenSegmentDisplay" ofType:@"fsh"];
    
    // compile shader program:
    _shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:@{} withAttributes:@{}];
    [ShaderEffect checkError];
    
    uModelViewProjectMatrix = [_shader uniformLocation:@"modelViewProjectionMatrix"];
    uPos = [_shader uniformLocation:@"pos"];
    uSize = [_shader uniformLocation:@"size"];
    uSource = [_shader uniformLocation:@"source"];
    
    uTexture = [_shader uniformLocation:@"texture"];
    
    uData = [_shader uniformLocation:@"data"];
    
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

    
    glGenBuffers(1, &_quadIndexBuffer);
    glGenBuffers(1, &_quadVertexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(QuadVertices), QuadVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(QuadIndices), QuadIndices, GL_STATIC_DRAW);
    

    
    return self;
}

- (SevenSegmentDisplay *) initWithTexture: (GLKTextureInfo *) texture component:(SpriteTexturePos) source {
    self = [self init];
    _texture = texture;
    _source = source;
    return self;
}

- (void) drawAt: (GLKVector3) position withInput:(int) input withTransform:(GLKMatrix4) viewProjectionMatrix{
    [_shader prepareToDraw];
    
    [ShaderEffect checkError];
    glEnable(GL_BLEND);
    //    glEnable(GL_ALPHA_BITS);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];
    
    
    int i = 0;
    // Use the texture @i
    glActiveTexture(GL_TEXTURE0 + i);
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    glUniform1i(uTexture, i);
    
    [ShaderEffect checkError];
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    
//    GLKVector4 _color = {1.0, 1.0, 1.0, 1.0};
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord1));
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    glUniform2f(uSize, 4.0 * _source.width / 16, 4.0 * _source.height / 8);
    glUniform3f(uPos,  position.x, position.y, position.z);
    glUniform1i(uData, input);
    glUniform4f(uSource, _source.u / _texture.width, _source.v /_texture.width, _source.twidth/_texture.width, _source.theight/_texture.height);
//    glVertexAttrib4fv(GLKVertexAttribColor, _color.v);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    
    [ShaderEffect checkError];
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];

    
}
@end
