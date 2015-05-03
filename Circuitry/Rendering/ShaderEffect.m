#import "ShaderEffect.h"

@interface ShaderEffect() {
    GLuint _program;
    NSDictionary * _uniforms;
}
@end

@implementation ShaderEffect

+ (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        // TODO: check this
        // NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(ShaderEffect *) initWithVertexSource: (NSString *)vertShaderPathname withFragmentSource:(NSString *)fragShaderPathname withUniforms:(NSDictionary *)uniforms withAttributes:(NSDictionary *)attributes; {
    
    GLuint vertShader, fragShader;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    [ShaderEffect compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname];
    
    // Create and compile fragment shader.
    [ShaderEffect compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname];
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    
    
    glBindAttribLocation(_program, GLKVertexAttribPosition,  "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal,    "normal");
    glBindAttribLocation(_program, GLKVertexAttribColor,     "color");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoord0");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord1, "texCoord1");
    
    // Link program.
    if (![ShaderEffect linkProgram:_program]) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        [NSException raise:@"Failed to link program" format:@"%d", _program];
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return self;
}

+ (void) checkError {
    int err;
    if((err = glGetError()) != GL_NO_ERROR) {
        NSDictionary *names = @{
                                @GL_INVALID_ENUM: @"GL_INVALID_ENUM",
                                 @GL_INVALID_VALUE: @"GL_INVALID_VALUE",
                                 @GL_INVALID_OPERATION: @"GL_INVALID_OPERATION",
                                 @GL_INVALID_FRAMEBUFFER_OPERATION: @"GL_INVALID_FRAMEBUFFER_OPERATION",
                                 @GL_OUT_OF_MEMORY: @"GL_OUT_OF_MEMORY"
                                 };
        [NSException raise:@"OpenGL Error" format:@"%@ (%d)", [names objectForKey:[NSNumber numberWithInt:err]], err];
    }
}

- (GLUniformLocation) uniformLocation:(NSString *) name {
    return glGetUniformLocation(_program, [name UTF8String]);
}

- (GLAttributeLocation) attributeLocation:(NSString *) name {
    return glGetAttribLocation(_program, [name UTF8String]);
}

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        [NSException raise:@"Failed to load vertex shader" format:@"url: %@", file];
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"%@ shader (%@) compile log:\n%s", type == GL_FRAGMENT_SHADER ? @"Fragment" : @"Vertex", file, log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (BOOL)validateProgram
{
    GLint logLength, status;
    
    glValidateProgram(_program);
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(_program, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


- (void) prepareToDraw {
    glUseProgram(_program);
//    glUniformMatrix4fv(0xffee, 1, 0, _modelViewProjectionMatrix.m);
//    glUniformMatrix3fv(0xffee, 1, 0, _normalMatrix.m);
}
@end
