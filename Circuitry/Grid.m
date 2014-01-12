#import "Grid.h"
#import "ShaderEffect.h"

@interface Grid() {
    ShaderEffect *_shader;
    float tx;
    float ty;
    float sx;
}

@end

@implementation Grid


// Uniform locations:
static GLint _uModelViewProjectMatrix;
static GLint _uGridMatrix;

// Buffer names:
static GLuint _vertexBuffer;
static GLuint _indexBuffer;

static int nVerts;
static int nLines;

- (void) setScale: (GLKVector3) scale translate:(GLKVector3) translate {
    float factor = round(log2f(scale.x));
    sx = 60.0 / exp2f(factor);
    tx = -translate.x / scale.x + fmodf(translate.x / scale.x, sx) - sx;
    ty = -translate.y / scale.x + fmodf(translate.y / scale.x, sx) - sx;
}

- (id) init {
    
    float gridWidth = 1.0;
    float gridHeight = 1.0;
    
    int nX = 32;
    int nY = 32;
    
    sx = 60.0;
    tx = ty = 0.0;

    nVerts = (nY * nX);
    
    nLines = nY * (nX - 1) + nX * (nY - 1);
    
    GLushort *lines = malloc(sizeof (GLushort) * 2 * nLines);
    GLfloat  *verts = malloc(sizeof (GLfloat)  * 3 * nVerts);
    
    int i = 0;
    
    for(int y = 0; y < nY; y++) {
        for(int x = 0; x < nX; x++) {
            verts[i++] = x * gridWidth;
            verts[i++] = y * gridHeight;
            verts[i++] = 0.0;
        }
    }
    
    i = 0;
    for(int y = 0; y < nY; y++) {
        for(int x = 0; x < nX - 1; x++) {
            lines[i++] = y * nX + x;
            lines[i++] = y * nX + x + 1;
        }
    }
    
    for(int x = 0; x < nX; x++) {
        for(int y = 0; y < nY - 1; y++) {
            lines[i++] = y * nX + x;
            lines[i++] = (y + 1) * nX + x;
        }
    }
    
    // Prepare shader
    NSString *vertShader = [[NSBundle mainBundle] pathForResource:@"Grid" ofType:@"vsh"];
    NSString *fragShader = [[NSBundle mainBundle] pathForResource:@"Grid" ofType:@"fsh"];
    
    if (!vertShader || !fragShader) {
        [[NSException exceptionWithName:@"Not Found" reason:@"Shader missing" userInfo:@{}] raise];
    }
    _shader = [[ShaderEffect alloc] initWithVertexSource:vertShader withFragmentSource:fragShader withUniforms:nil withAttributes:nil];
    
    _uModelViewProjectMatrix = [_shader getUniformLocation:@"modelViewProjectionMatrix"];
    _uGridMatrix = [_shader getUniformLocation:@"gridMatrix"];
    
    glGenBuffers(1, &_indexBuffer);
    glGenBuffers(1, &_vertexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    // push data to GPU:
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, nVerts * sizeof(GLfloat) * 3, verts, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 2 * nLines * sizeof(GLushort), lines, GL_STATIC_DRAW);
    
    free(lines);
    free(verts);
    
    return self;
}

- (void) dealloc {
}
- (void) drawWithStack:(GLKMatrixStackRef) stack {
    
    [_shader prepareToDraw];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    GLKMatrix4 _gridMatrix = GLKMatrix4Multiply(
                       GLKMatrix4MakeTranslation(tx, ty, 0.0),
                       GLKMatrix4MakeScale(sx, sx, 1.0));
    

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glLineWidth(1.0);
    
    // Specify how the GPU looks up the data 
    glVertexAttribPointer(
                          GLKVertexAttribPosition, // the currently bound buffer holds the data 
                          3,                       // number of coordinates per vertex 
                          GL_FLOAT,                // the data type of each component 
                          GL_FALSE,                // can the data be scaled 
                          3 * sizeof(GLfloat),     // how many bytes per vertex (3 floats per vertex)
                          0);                      // offset to the first coordinate, in this case 0 
    
    glUniformMatrix4fv(_uModelViewProjectMatrix, 1, 0, GLKMatrixStackGetMatrix4(stack).m);
    glUniformMatrix4fv(_uGridMatrix, 1, 0, _gridMatrix.m);
    glDrawElements(GL_LINES, nLines * 2, GL_UNSIGNED_SHORT, 0);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
}


@end
