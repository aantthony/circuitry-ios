//
//  CircuitImagePreview.m
//  Circuitry
//
//  Created by Anthony Foster on 10/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitImagePreview.h"
#import "ViewController.h"

#import "Viewport.h"
@interface CircuitImagePreview () {
    GLKMatrixStackRef _stack;
    Viewport *_viewport;
    EAGLContext *_context;
    GLuint _framebuffer;
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
}

@end

@implementation CircuitImagePreview
- (id) init {
    self = [super init];
    _context = [ViewController context];
    [EAGLContext setCurrentContext:_context];
    [ShaderEffect checkError];
    ImageAtlas *atlas = [ViewController atlas];
    _viewport = [[Viewport alloc] initWithContext:_context atlas:atlas];
    [ShaderEffect checkError];
    _stack = GLKMatrixStackCreate(NULL);
    
    int width = 400;
    int height = 400;
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    [ShaderEffect checkError];
    glGenRenderbuffers(1, &_colorRenderbuffer);
    
    [ShaderEffect checkError];
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    
    [ShaderEffect checkError];
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
    
    [ShaderEffect checkError];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    /*
     GL_INVALID_OPERATION is generated if the default framebuffer object name 0 is bound.
     
     GL_INVALID_OPERATION is generated if renderbuffer is neither 0 nor the name of an existing renderbuffer object.
     */
    [ShaderEffect checkError];
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    [ShaderEffect checkError];
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
    
    [ShaderEffect checkError];
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
    }

    
    [ShaderEffect checkError];

    return self;
}

- (CALayer *) layerForCircuit:(Circuit *) circuit {
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.opaque = YES;
    [EAGLContext setCurrentContext:_context];
    
    [ShaderEffect checkError];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    [ShaderEffect checkError];
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    
    [ShaderEffect checkError];
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    
    [ShaderEffect checkError];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    [ShaderEffect checkError];
    
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    [_viewport drawWithStack:_stack];

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    return layer;
}

- (NSData *) png:(Circuit *)circuit {
    
    CALayer *layer = [self layerForCircuit:circuit];
    
    UIGraphicsBeginImageContext([layer frame].size);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil);
    
    return UIImagePNGRepresentation(outputImage);
}

- (void) dealloc {
    glDeleteFramebuffers(1, &_framebuffer);
    glDeleteRenderbuffers(1, &_colorRenderbuffer);
    glDeleteRenderbuffers(1, &_depthRenderbuffer);
    CFRelease(_stack);
}
@end
