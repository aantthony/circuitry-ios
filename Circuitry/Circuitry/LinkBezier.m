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
}

@end

@implementation LinkBezier




typedef struct {
    GLuint index;
} Vertex;


ShaderEffect *shader;

// uniform locations:
GLint uTexture;
GLint uModelViewProjectMatrix;
GLint uSize;
GLint uPos;

// buffer names:
GLuint _vertexBuffer;

int nVerts = 128;

- (id) init {
    self = [super init];
    
    Vertex *verticies = malloc(sizeof(Vertex) * nVerts);
    for(int i = 0; i < nVerts; i++) {
        verticies[i].index = i;
    }
    
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"LinkBezier" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"LinkBezier" ofType:@"fsh"];
    
    // compile shader program:
    shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:@{} withAttributes:@{}];
    
    glGenBuffers(1, &_vertexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * nVerts, verticies, GL_STATIC_DRAW);
    return self;
}

- (void) drawFrom: (GLKVector2) A to: (GLKVector2) B withTransform:(GLKMatrix4) viewProjectionMatrix {
    
    [shader prepareToDraw];
        
    glDisable(GL_TEXTURE_2D);
//    glEnable(GL_BLEND);
//    glEnable(GL_ALPHA_BITS);
    
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 1, GL_UNSIGNED_BYTE, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, index));
    glEnableVertexAttribArray( GLKVertexAttribPosition );
    
    glUniformMatrix4fv(uModelViewProjectMatrix, 1, 0, viewProjectionMatrix.m);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, nVerts);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);

}



@end
