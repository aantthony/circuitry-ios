#import "ViewController.h"

@interface ViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    float beginGestureScale;
    
}
@property (strong, nonatomic) EAGLContext *context;

@property Circuit *circuit;
@property Viewport *viewport;

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
    
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"nand" withExtension:@"json"];
    NSInputStream *stream = [NSInputStream inputStreamWithURL:path];
    [stream open];
    _circuit = [Circuit circuitWithStream: stream];
    _viewport.circuit = _circuit;
//    [[[UIAlertView alloc] initWithTitle:_circuit.name message:_circuit.description delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
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

    [_viewport setProjectionMatrix:_modelViewProjectionMatrix];
//   _rotation += self.timeSinceLastUpdate * 0.5f;
    _rotation += 1.0;
    [_viewport update];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 0.0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDepthFunc(GL_LEQUAL);
    [_viewport draw];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    return YES;
}


- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos {
    __block CircuitObject *o;
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        o = object;
        *stop = YES;
    }];
    return o;
}

#pragma mark -  Gesture methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		beginGestureScale = _viewport.scale;
	}
	return YES;
}

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    
    CircuitObject *o = [self findCircuitObjectAtPosition:GLKVector3Make(recognizer.view.center.x, recognizer.view.center.y, 0.0)];
    if (!o) return;
    CGPoint translation = [recognizer translationInView:self.view];
    
//    o->pos.x += translation.x;
//    o->pos.y += translation.y;

    [_viewport translate: GLKVector3Make(translation.x, translation.y, 0.0)];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    _viewport.scale = beginGestureScale * recognizer.scale;
}
- (IBAction) handleLongPressGesture:(UIGestureRecognizer *)recognizer {
    NSLog(@"long press");
}



#pragma mark -  UIResponder methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"begin");
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"moved");
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"ended");
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"cancelled");
}

@end
