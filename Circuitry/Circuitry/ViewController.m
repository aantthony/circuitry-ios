//
//  ViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 9/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    Viewport *_viewport;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    _viewport = [[Viewport alloc] initWithContext:self.context];
    
//    [[[UIAlertView alloc] initWithTitle:@"Title" message:@"test" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
//    glDeleteBuffers(1, &_vertexBuffer);
//    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    projectionMatrix = GLKMatrix4MakeOrtho(0.0, 1024.0, 768.0, 0.0, -10.0, 10.0);
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with ES2
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.5 * floor(_rotation), 0.0f, 0.0f);
      GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotatio0, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    _viewport.modelViewProjectionMatrix = _modelViewProjectionMatrix;
    
//   _rotation += self.timeSinceLastUpdate * 0.5f;
    _rotation += 1.0;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 0.0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDepthFunc(GL_LEQUAL);
 
//    [bgTest drawAtPoint: GLKVector3Make(0.0, 0.0, 0.0) withTransform: _modelViewProjectionMatrix];
    [_viewport draw];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    return YES;
}



@end
