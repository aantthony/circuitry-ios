#import "ViewController.h"

#import "Viewport.h"
#import "Circuit.h"
#import "Sprite.h"
#import "HUD.h"
#import "DragGateGestureRecognizer.h"
#import "CreateGatePanGestureRecognizer.h"

@interface ViewController () {
    GLuint _program;
    
    IBOutlet UIPinchGestureRecognizer *_pinchGestureRecognizer;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLKMatrixStackRef _stack;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    float beginGestureScale;
    
    CircuitObject *beginLongPressGestureObject;
    GLKVector3 beginLongPressGestureOffset;
    
    BOOL isAnimatingScaleToSnap;
    BOOL toolbeltTouchIntercept;
    
    
    Sprite *bg;
    
}
@property (strong, nonatomic) EAGLContext *context;

@property Circuit *circuit;
@property Viewport *viewport;
@property HUD *hud;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isAnimatingScaleToSnap = NO;
    toolbeltTouchIntercept = NO;
    beginGestureScale = 0.0;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    [self checkError];
    _viewport = [[Viewport alloc] initWithContext:self.context];
    _hud = [[HUD alloc] init];
    _hud.viewPort = _viewport;
    
    [self checkError];
    GLKTextureInfo *bgTexture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"background" withExtension:@"png"]];
    [self checkError];
    bg = [[Sprite alloc] initWithTexture:bgTexture];
    [self checkError];
    
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
    
    _stack = GLKMatrixStackCreate(NULL);
    [self checkError];
    [self loadShaders];
    [self checkError];
    glEnable(GL_DEPTH_TEST);
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    [self checkError];
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
    [self checkError];
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    CGRect boundary = self.view.bounds;
    projectionMatrix = GLKMatrix4MakeOrtho(0.0, boundary.size.width, boundary.size.height, 0.0, -10.0, 10.0);
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
    if (!isAnimatingScaleToSnap && beginGestureScale != 0.0 && !_pinchGestureRecognizer.numberOfTouches) {
        beginGestureScale = 0.0;
        isAnimatingScaleToSnap = YES;
    }

    if (isAnimatingScaleToSnap) {
        float lEnd = round(log2f(_viewport.scale));
        if (lEnd > 2.0) lEnd = 2.0; // maximum zoom
        float lNow = log2f(_viewport.scale);
        float k = 0.1;
        if (fabsf(lEnd - lNow) < 0.001) {
            k = 1.0;
            isAnimatingScaleToSnap = NO;
        }
        
        // TODO: this is a bit of a hack. Clean up the translate / scale math so that isn't so disgusting:
        CGPoint screenPos = PX(self.view.contentScaleFactor, CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2));
        GLKVector3 aPos = [_viewport unproject: screenPos];
        _viewport.scale = exp2f(lNow + (lEnd - lNow) * k);
        GLKVector3 bPos = [_viewport unproject: screenPos];
        
        // We want modelViewMatrix * curPos = newModelViewMatrix * curPos
        
        // A v = B v.. so what is B...
        [_viewport translate: GLKVector3Make(_viewport.scale * (bPos.x - aPos.x), _viewport.scale * (bPos.y - aPos.y), 0.0)];
        
    }
//   _rotation += self.timeSinceLastUpdate * 0.5f;
    _rotation += 1.0;
    [_circuit simulate:4096];
    [_viewport update];
}

- (void) checkError {
    int err;
    if((err = glGetError()) != GL_NO_ERROR) {
        NSDictionary *names = @{
                                 @GL_INVALID_ENUM: @"GL_INVALID_ENUM",
                                 @GL_INVALID_VALUE: @"GL_INVALID_VALUE",
                                 @GL_INVALID_OPERATION: @"GL_INVALID_OPERATION",
                                 @GL_INVALID_FRAMEBUFFER_OPERATION: @"GL_INVALID_FRAMEBUFFER_OPERATION",
                                 @GL_OUT_OF_MEMORY: @"GL_OUT_OF_MEMORY",
                                 @GL_STACK_UNDERFLOW: @"GL_STACK_UNDERFLOW",
                                 @GL_STACK_OVERFLOW: @"GL_STACK_OVERFLOW"
                                 };
        [NSException raise:@"OpenGL Error" format:@"%@ (%d)", [names objectForKey:[NSNumber numberWithInt:err]], err];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self checkError];
    glClearColor(0.0, 0.0, 0.0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(0);
    [self checkError];
    GLKMatrixStackLoadMatrix4(_stack, _modelViewProjectionMatrix);
    [bg drawWithSize:GLKVector2Make(rect.size.width, rect.size.height) withTransform:_modelViewProjectionMatrix];
    [self checkError];
    [_viewport drawWithStack:_stack];
    [_hud drawWithStack:_stack];
    [self checkError];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    return YES;
}

CGPoint PX(float contentScaleFactor, CGPoint pt) {
    return CGPointMake(contentScaleFactor * pt.x, contentScaleFactor * pt.y);
}

#pragma mark -  Gesture methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        isAnimatingScaleToSnap = NO;
		beginGestureScale = _viewport.scale;
	}
    if ([gestureRecognizer isKindOfClass:[DragGateGestureRecognizer class]]) {
        DragGateGestureRecognizer *recogniser = (DragGateGestureRecognizer *)gestureRecognizer;
        ;
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [recogniser locationInView:self.view])];
        // only accept long presses on circuit objects:
        CircuitObject *o;
        if ((o = [_viewport findCircuitObjectAtPosition:position])) {
            beginLongPressGestureObject = o;
            GLKVector3 objectPosition = *(GLKVector3 *) &beginLongPressGestureObject->pos;
            beginLongPressGestureOffset = GLKVector3Subtract(objectPosition, position);
            return YES;
        }
        
        return NO;
    } else if ([gestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]]) {
        // only starts if the finger is on the toolbelt
        CGPoint location = [gestureRecognizer locationInView:self.view];
        if (!CGRectContainsPoint(_hud.toolbelt.bounds, location)) {
            return NO;
        }
        CircuitObject *o = [_circuit addObject:[_circuit getProcessById:@"xor"]];
        
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [gestureRecognizer locationInView:self.view])];
        
        beginLongPressGestureObject = o;
        o->pos.x = position.x - 200.0;
        o->pos.y = position.y - 100.0;
        GLKVector3 objectPosition = *(GLKVector3 *) &beginLongPressGestureObject->pos;
        beginLongPressGestureOffset = GLKVector3Subtract(objectPosition, position);
        return YES;
    } else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // pan
        UIPanGestureRecognizer *recogniser = (UIPanGestureRecognizer *)gestureRecognizer;
        ;
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [recogniser locationInView:self.view])];
        if ([_viewport findCircuitObjectAtPosition:position]) {
            return NO;
        }
        return YES;
    }

	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]]) return NO;
    // TODO: test this
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) return YES;
    
    return NO;
}


- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    [_viewport translate: GLKVector3Make(translation.x, translation.y, 0.0)];
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (IBAction)handleDragGateGesture:(UIPanGestureRecognizer *)sender {
    if (!beginLongPressGestureObject) {
        NSLog(@"wtf %@", sender);
        return;
    }
    
    CircuitObject *object = beginLongPressGestureObject;
    
    if ([sender numberOfTouches] != 1) {
        sender.enabled = NO;
        sender.enabled = YES;
        return;
    }
    GLKVector3 curPos = [_viewport unproject: PX(self.view.contentScaleFactor, [sender locationOfTouch:0 inView:self.view])];
    
    GLKVector3 newPos = GLKVector3Add(curPos, beginLongPressGestureOffset);
    object->pos.x = newPos.x;
    object->pos.y = newPos.y;
    object->pos.z = newPos.z;
}

- (IBAction)handleCreateGateGesture:(UIPanGestureRecognizer *)sender {
    return [self handleDragGateGesture:sender];
}

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    
    CGPoint screenPos = PX(self.view.contentScaleFactor, [recognizer locationInView:self.view]);
    GLKVector3 aPos = [_viewport unproject: screenPos];
    _viewport.scale = beginGestureScale * recognizer.scale;
    GLKVector3 bPos = [_viewport unproject: screenPos];
    
    // We want modelViewMatrix * curPos = newModelViewMatrix * curPos
    
    // A v = B v.. so what is B...
    [_viewport translate: GLKVector3Make(_viewport.scale * (bPos.x - aPos.x), _viewport.scale * (bPos.y - aPos.y), 0.0)];
    
//#define LOG_TEST 0
#ifdef LOG_TEST
    GLKVector3 cPos = [_viewport unproject: PX(self.view.contentScaleFactor, [recognizer locationInView:self.view])];
    NSLog(@"((%.2f, %.2f : %.2f) , (%.2f, %.2f : %.2f))", aPos.x, cPos.x, aPos.x - cPos.x , aPos.y, cPos.y, aPos.y - cPos.y);
#endif
}

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender {
    // TODO: try not handling the tap gesture when there is nothing to tap.
    for(int i = 0; i < sender.numberOfTouches; i++) {
        CGPoint screenPos = [sender locationOfTouch:i inView:self.view];
        
        // world space coordinates
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, screenPos)];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        
        if (!object) return;
        if (object->type == [_circuit getProcessById:@"in"]) {
            object->out = !object->out;
            [_circuit didUpdateObject:object];
        }
    }
    
}



#pragma mark -  UIResponder methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {

}

@end
