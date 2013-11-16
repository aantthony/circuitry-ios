//
//  ShaderEffect.m
//  Circuitry
//
//  Created by Anthony Foster on 16/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import "ShaderEffect.h"

@interface ShaderEffect()
@property GLuint program;
@end

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

struct uniform {
    GLuint index;
    int type;
    const char* name;
};

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
        NSLog(@"Program link log:\n%s", log);
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
    
    GLuint _program;
    
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
    __block int index = NUM_ATTRIBUTES;
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    for (NSString* attribName in attributes) {
        NSDictionary *dict = [attributes objectForKey:attribName ];
        NSString *type = [dict objectForKey:@"type"];
        glBindAttribLocation(_program, index++, [attribName UTF8String]);
    }
    
    // Link program.
    if (![ShaderEffect linkProgram:_program]) {
        [NSException raise:@"Failed to link program" format:@"%d", _program];
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
        
        return NO;
    }
    
    // Get uniform locations.
    for (NSString* uniformName in uniforms) {
        NSDictionary *dict = [uniforms objectForKey:uniformName ];
        NSString *type = [dict objectForKey:@"type"];
        glGetUniformLocation(_program, [uniformName UTF8String]);
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

- (void) setUniform:(NSString *) name withValue:(id) value {
    
}


+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
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
        NSLog(@"Shader compile log:\n%s", log);
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

- (void) prepareToDraw {
    
}
@end
