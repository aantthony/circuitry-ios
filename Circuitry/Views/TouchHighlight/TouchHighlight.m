//
//  TouchHighlight.m
//  Circuitry
//
//  Created by Anthony Foster on 19/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import "TouchHighlight.h"
#import "ShaderEffect.h"

@interface TouchHighlight()

// Programs:
@property (nonatomic) ShaderEffect *shader;

// Attribute locations:
@property (nonatomic) GLUniformLocation uModelViewProjectionMatrix;
@property (nonatomic) GLUniformLocation uPos;
@property (nonatomic) GLUniformLocation uColor;
@property (nonatomic) GLUniformLocation uRadius;

// Buffers
@property (nonatomic) GLuint quadIndexBuffer;
@property (nonatomic) GLuint quadVertexBuffer;

@end

// Attribute:
typedef struct {
    float Position[3];
    float TexCoord1[2];
} Vertex;

@implementation TouchHighlight
- (instancetype) init {
    self = [super init];
    
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"TouchHighlight" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"TouchHighlight" ofType:@"fsh"];
    
    // compile shader program:
    _shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:@{} withAttributes:@{}];
    [ShaderEffect checkError];
    
    _uModelViewProjectionMatrix = [_shader uniformLocation:@"modelViewProjectionMatrix"];
    _uPos = [_shader uniformLocation:@"pos"];
    _uRadius = [_shader uniformLocation:@"radius"];
    _uColor = [_shader uniformLocation:@"color"];
    
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

- (BOOL) drawOutFromPosition:(GLKVector2)position progress:(GLfloat)progress withTransform:(GLKMatrix4) viewProjectionMatrix {
    [_shader prepareToDraw];
    
    [ShaderEffect checkError];
    glEnable(GL_BLEND);
    //    glEnable(GL_ALPHA_BITS);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord1));
    glUniformMatrix4fv(_uModelViewProjectionMatrix, 1, 0, viewProjectionMatrix.m);
    if (progress < 0.0) progress = 0.0;
    else if (progress > 1.0) progress = 1.0;
    GLfloat radius = 100.0 + progress * 100.0;
    GLfloat alpha = 0.4 - progress;
    glUniform3f(_uPos,  position.x - radius, position.y - radius, 0);
    glUniform4f(_uColor, 1.0, 1.0, 1.0, alpha);
    glUniform1f(_uRadius, radius);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    
    [ShaderEffect checkError];
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];
    return NO;

}
- (BOOL) drawTouchMatchingAtPosition:(GLKVector2)position progress:(GLfloat)progress withTransform:(GLKMatrix4) viewProjectionMatrix {
    [_shader prepareToDraw];
    
    [ShaderEffect checkError];
    glEnable(GL_BLEND);
    //    glEnable(GL_ALPHA_BITS);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord1));
    glUniformMatrix4fv(_uModelViewProjectionMatrix, 1, 0, viewProjectionMatrix.m);
    if (progress < 0.0) progress = 0.0;
    else if (progress > 1.0) progress = 1.0;
    GLfloat oneMinusP = (1-progress);
    GLfloat radius = 300 * oneMinusP * oneMinusP;
    GLfloat alpha = progress;
    glUniform3f(_uPos,  position.x - radius, position.y - radius, 0);
    glUniform4f(_uColor, 1.0, 1.0, 1.0, alpha);
    glUniform1f(_uRadius, radius);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    
    [ShaderEffect checkError];
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    [ShaderEffect checkError];
    return NO;
}
@end
