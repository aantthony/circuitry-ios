//
//  LinkBezier.m
//  Circuitry
//
//  Created by Anthony Foster on 3/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "LinkBezier.h"
#import "ShaderEffect.h"
@interface LinkBezier() {
    ShaderEffect *shader;
    
    // buffer names:
    GLuint _vertexBuffer;
    GLint uModelViewProjectMatrix;
    GLint uColor1;
    GLint uColor2;
    GLint uA;
    GLint uB;
    int nVerts;
}

@end

@implementation LinkBezier

typedef struct {
    GLuint index;
} Vertex;

- (id) init {
    self = [super init];
    nVerts = 64;
    Vertex *verticies = malloc(sizeof(Vertex) * nVerts);
    for(int i = 0; i < nVerts; i++) {
        verticies[i].index = i;
    }
    
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"LinkBezier" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"LinkBezier" ofType:@"fsh"];

    // compile shader program:
    shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:@{} withAttributes:@{}];
    [ShaderEffect checkError];
    
    uModelViewProjectMatrix = [shader getUniformLocation:@"modelViewProjectionMatrix"];
    uColor1 = [shader getUniformLocation:@"color1"];
    uColor2 = [shader getUniformLocation:@"color2"];
    uA = [shader getUniformLocation:@"A"];
    uB = [shader getUniformLocation:@"B"];
//    return self;
    glGenBuffers(1, &_vertexBuffer);
    [ShaderEffect checkError];
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * nVerts, verticies, GL_STATIC_DRAW);
    return self;
}

- (void) drawFrom: (GLKVector2) A to: (GLKVector2) B withColor1:(GLKVector3)color1 color2: (GLKVector3) color2 withTransform:(GLKMatrix4) viewProjectionMatrix {
    [ShaderEffect checkError];
    [shader prepareToDraw];
    [ShaderEffect checkError];
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    [ShaderEffect checkError];
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    [ShaderEffect checkError];
    glVertexAttribPointer(GLKVertexAttribPosition, 1, GL_UNSIGNED_BYTE, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, index));
    glEnableVertexAttribArray( GLKVertexAttribPosition );
    [ShaderEffect checkError];
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    glUniform2f(uA, A.x, A.y);
    glUniform2f(uB, B.x, B.y);
    glUniform3f(uColor1, color1.r, color1.g, color1.b);
    glUniform3f(uColor2, color2.r, color2.g, color2.b);
//    glUniform3f(uWireColor, 0.1960784314, 1.0, 3098039216);
    [ShaderEffect checkError];
    [ShaderEffect checkError];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, nVerts);
    [ShaderEffect checkError];
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    [ShaderEffect checkError];
}



@end
