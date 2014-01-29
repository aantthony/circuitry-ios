#import "ViewController.h"

#import "Viewport.h"
#import "Circuit.h"
#import "Sprite.h"
#import "HUD.h"
#import "DragGateGestureRecognizer.h"
#import "CreateGatePanGestureRecognizer.h"
#import "CreateLinkGestureRecognizer.h"

#import "ToolbeltItem.h"

@interface ViewController () {
    GLuint _program;
    
    IBOutlet UIPinchGestureRecognizer *_pinchGestureRecognizer;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    GLKMatrixStackRef _stack;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    float beginGestureScale;
    
    CircuitObject *beginLongPressGestureObject;
    GLKVector3 beginLongPressGestureOffset;
    
    CGPoint panVelocity;
    
    
    BOOL isAnimatingScaleToSnap;
    BOOL toolbeltTouchIntercept;
    
    BOOL draggingOutFromToolbeltLockY;
    CGPoint draggingOutFromToolbeltStart;
    
    Sprite *bg;
    
    BOOL animatingPan;
    
}
@property (strong, nonatomic) EAGLContext *context;

@property ImageAtlas *atlas;
@property Circuit *circuit;
@property Viewport *viewport;
@property HUD *hud;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
@end

@implementation ViewController

- (void) configureToolbeltItems {
    
    NSMutableArray *items = [NSMutableArray array];
    
    
    ToolbeltItem *item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"in"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"or"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"and"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"not"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"nor"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"xor"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"nand"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"xnor"];
    [items addObject:item];
    
    item = [[ToolbeltItem alloc] init];
    item.type = [_circuit getProcessById:@"out"];
    [items addObject:item];
    
    _hud.toolbelt.items = items;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    panVelocity = CGPointMake(0.0, 0.0);
    
    isAnimatingScaleToSnap = NO;
    toolbeltTouchIntercept = NO;
    animatingPan = NO;
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
    
    _atlas = [ImageAtlas imageAtlasWithName:@"circuit"];
    
    _viewport = [[Viewport alloc] initWithContext:self.context atlas: _atlas];
    _hud = [[HUD alloc] initWithAtlas:_atlas];
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
    
    [self configureToolbeltItems];
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
    
    // time differnce in seconds (float)
    NSTimeInterval dt = self.timeSinceLastUpdate;
    
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
    
    [_viewport translate: GLKVector3Make(panVelocity.x * dt, panVelocity.y * dt, 0.0)];
    if (animatingPan) {
        // momentum deceleration / friction:
        panVelocity.x -= panVelocity.x * dt * 10.0;
        panVelocity.y -= panVelocity.y * dt * 10.0;
        if (fabs(panVelocity.x) < 0.1 && fabs(panVelocity.y) < 0.1) {
            [self stopPanAnimation];
        }
    }
    int changes = 0;
    changes += [_circuit simulate:4096];
    changes += [_viewport update: dt];
    changes += [_hud update: dt];
//    NSLog(@"Changed!");
    if (animatingPan || isAnimatingScaleToSnap || changes) {
        self.paused = NO;
    } else {
        self.paused = YES;
    }
}

// Faster one-part variant, called from within a rotating animation block, for additional animations during rotation.
// A subclass may override this method, or the two-part variants below, but not both.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration NS_AVAILABLE_IOS(3_0) {
    self.paused = NO;
//    [self update];
//    [EAGLContext setCurrentContext:self.context];
//    [self glkView:self.view drawInRect:self.view.frame];
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
//    glDisable(GL_DEPTH_TEST);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

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

// Take a pt screen coordinate and translate it to pixel screen coordinates, because OpenGL only deals with pixels.
CGPoint PX(float contentScaleFactor, CGPoint pt) {
    return CGPointMake(contentScaleFactor * pt.x, contentScaleFactor * pt.y);
}

- (void) stopPanAnimation {
    panVelocity = CGPointZero;
    animatingPan = NO;
}
#pragma mark -  Gesture methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    [self unpause];
    [self stopPanAnimation];
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        isAnimatingScaleToSnap = NO;
		beginGestureScale = _viewport.scale;
        return YES;
	}
    
    if ([gestureRecognizer isKindOfClass:[CreateLinkGestureRecognizer class]]) {
        // Create a link from a gate, or move a link that is connected to a gate
        
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [gestureRecognizer locationInView:self.view])];
        
        CircuitObject *o;
        // find the object under the touch:
        if ((o = [_viewport findCircuitObjectAtPosition:position])) {
            // calculate the offset (which will be used to determine which output to edit)
            GLKVector3 offset = GLKVector3Subtract(position, *(GLKVector3 *)&o->pos);
            if (offset.x < 150.0) {
                // Left side: editing something connected to a gate (todo: don't make this guess, just use find attachment at index or something which finds either inlets or outlets, whichever is closer)
                CircuitLink *existing = [_viewport findCircuitLinkAtOffset:offset attachedToObject:o];
                if (!existing) return NO;
                // edit an existing one:
                _viewport.currentEditingLink = existing;
                _viewport.currentEditingLinkSource = existing->source;
                _viewport.currentEditingLinkSourceIndex = existing->sourceIndex;
                _viewport.currentEditingLinkTarget = existing->target;
                _viewport.currentEditingLinkTargetIndex = existing->targetIndex;
                return YES;
            } else {
                // Create a link from an existing gate
                int index = [_viewport findOutletIndexAtOffset:offset attachedToObject:o];
                if (index == -1) return NO;
                _viewport.currentEditingLink = NULL;
                _viewport.currentEditingLinkSource = o;
                _viewport.currentEditingLinkSourceIndex = index;
                _viewport.currentEditingLinkTargetPosition = position;
                return YES;
            }
        }
        // not creating/editing a link:
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[DragGateGestureRecognizer class]]) {
        // Drag a gate. This is done with a pan gesture recogniser that is only begins if the touch starts on top of a gate 
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
        // Dragging the background, defer this to the other pan gesture recognizer.
        return NO;
    } else if ([gestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]]) {
        // only starts if the finger is on the toolbelt
        CGPoint location = [gestureRecognizer locationInView:self.view];
        if (!CGRectContainsPoint(_hud.toolbelt.bounds, location)) {
            return NO;
        }
        
        CGPoint p = [gestureRecognizer locationInView:self.view];
        p.x = 0.0;
        
        draggingOutFromToolbeltLockY = YES;
        int index = [_hud.toolbelt indexAtPosition:p];
        if (index == -1) return NO;
        _hud.toolbelt.currentObjectIndex = index;
        draggingOutFromToolbeltStart = p;
        return YES;
    } else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // drag view pan
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

- (void) unpause {
    self.paused = NO;
}

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    [_viewport translate: GLKVector3Make(translation.x, translation.y, 0.0)];
    // this makes it so next time "handlePanGesture:" is called, translation will be relative to the last one. (ie. translation is a delta)
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // give it some momentum
        panVelocity = [recognizer velocityInView:self.view];
        animatingPan = YES;
    }
    [self unpause];
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
    
    // world space position of touch:
    GLKVector3 curPos = [_viewport unproject: PX(self.view.contentScaleFactor, [sender locationOfTouch:0 inView:self.view])];
    
    // This moves it so that the user can drag the gate from places other than the gates top left corner
    GLKVector3 newPos = GLKVector3Add(curPos, beginLongPressGestureOffset);
    object->pos.x = newPos.x;
    object->pos.y = newPos.y;
    object->pos.z = newPos.z;
    [self unpause];
}

- (IBAction)handleCreateGateGesture:(UIPanGestureRecognizer *)sender {
    
    if (draggingOutFromToolbeltLockY) {
        // still dragging it out of the toolbelt
        
        if ([sender numberOfTouches] != 1) {
            sender.enabled = NO;
            sender.enabled = YES;
            return;
        }
        CGPoint p = [sender locationOfTouch:0 inView:self.view];
        
        CGPoint diff = CGPointMake(p.x - draggingOutFromToolbeltStart.x, p.y - draggingOutFromToolbeltStart.y);
        if (diff.x > _hud.toolbelt.listWidth) {
            GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, p)];
            
            // the gate is out of the toolbelt, act the same as the normal drag gate gesture from now on:
            draggingOutFromToolbeltLockY = NO;
            
            ToolbeltItem *item = _hud.toolbelt.items[_hud.toolbelt.currentObjectIndex];
            
            
            // Create a new gate object, and start dragging the gate (as if the drag gate gesture recognizer started)
            
            CircuitObject *o = [_circuit addObject:item.type];
            beginLongPressGestureObject = o;
            o->pos.x = position.x;
            o->pos.y = position.y - 100.0;
            GLKVector3 objectPosition = *(GLKVector3 *) &beginLongPressGestureObject->pos;

            beginLongPressGestureOffset = GLKVector3Subtract(objectPosition, position);
            
            beginLongPressGestureObject = o;
            
            _hud.toolbelt.currentObjectIndex = -1;
        } else {
            _hud.toolbelt.currentObjectX = diff.x;
        }
    } else {
        // the gate is out of the toolbelt:
        [self handleDragGateGesture:sender];
    }
    [self unpause];
}

- (IBAction)handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        // If there is no active gate in creation, then just cancel.
        _viewport.currentEditingLinkSource = NULL;
        _viewport.currentEditingLinkTarget = NULL;
        [self unpause];
        return;
    }
    if (!_viewport.currentEditingLinkSource || [sender numberOfTouches] != 1) {
        // If the number of touches changes from 1, then cancel.
        // This isn't ideal, but it is simpler to deal with for now.
        sender.enabled = NO;
        sender.enabled = YES;
        [self unpause];
        return;
    }
    // world space:
    GLKVector3 curPos = [_viewport unproject: PX(self.view.contentScaleFactor, [sender locationOfTouch:0 inView:self.view])];

    CircuitObject *target;
    if ((target = [_viewport findCircuitObjectAtPosition:curPos])) {
        
        GLKVector3 offset = GLKVector3Subtract(curPos, *(GLKVector3 *)&target->pos);
        int targetIndex = -1;
        if (target == _viewport.currentEditingLinkSource && offset.x > 180.0) {
            
        } else {
            targetIndex = [_viewport findInletIndexAtOffset:offset attachedToObject:target];
        }
        
        if (targetIndex != -1) {
            // if the one suggested by findInletIndexAtOffset is taken, go to the next in this while loop:
            while(targetIndex < target->type->numInputs && target->inputs[targetIndex]) {
                if (target == _viewport.currentEditingLinkTarget && targetIndex == _viewport.currentEditingLinkTargetIndex) {
                    // nothings changed
                    return;
                }
                targetIndex++;
            }
            
            if (targetIndex < target->type->numInputs) {
                // Connect a link to the target at the index:
                _viewport.currentEditingLinkTarget = target;
                if (_viewport.currentEditingLink) {
                    // if we are dragging a link out from another inlet, then delete that old link (we will create a new link to target instead of modifying the old one to make circuit simulation refreshes simpler)
                    [_circuit removeLink:_viewport.currentEditingLink];
                }
                // Create a new link and tell the viewport renderer that it is the one being edited:
                _viewport.currentEditingLinkTargetIndex = targetIndex;
                CircuitLink *newLink = [_circuit addLink:_viewport.currentEditingLinkSource index:_viewport.currentEditingLinkSourceIndex to:target index:targetIndex];
                _viewport.currentEditingLink = newLink;
            }
        }
        
        
    } else {
        // Couldn't find a gate under the touch, remove the link being dragged if one exists
        if (_viewport.currentEditingLink) {
           [_circuit removeLink:_viewport.currentEditingLink];
            _viewport.currentEditingLink = NULL;
            _viewport.currentEditingLinkTarget = NULL;
        }
    }
    // set the green wire to end at curPos (which is drawn by Viewport)
    _viewport.currentEditingLinkTargetPosition = curPos;
    [self unpause];
}

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    // Zoom:
    CGPoint screenPos = PX(self.view.contentScaleFactor, [recognizer locationInView:self.view]);
    
    GLKVector3 aPos = [_viewport unproject: screenPos];
    _viewport.scale = beginGestureScale * recognizer.scale;
    GLKVector3 bPos = [_viewport unproject: screenPos];
    
    // We want modelViewMatrix * curPos = newModelViewMatrix * curPos (i.e., scaling should not translate the center point of the gesture)
    
    // A v = B v.. so what is B...
    [_viewport translate: GLKVector3Make(_viewport.scale * (bPos.x - aPos.x), _viewport.scale * (bPos.y - aPos.y), 0.0)];
    [self unpause];
    
//#define LOG_TEST 0
#ifdef LOG_TEST
    GLKVector3 cPos = [_viewport unproject: PX(self.view.contentScaleFactor, [recognizer locationInView:self.view])];
    // the difference should be (0,0,0)
    NSLog(@"((%.2f, %.2f : %.2f) , (%.2f, %.2f : %.2f))", aPos.x, cPos.x, aPos.x - cPos.x , aPos.y, cPos.y, aPos.y - cPos.y);
#endif
}

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender {
    BOOL hit = NO;
    // TODO: try not handling the tap gesture when there is nothing to tap.
    for(int i = 0; i < sender.numberOfTouches; i++) {
        CGPoint screenPos = [sender locationOfTouch:i inView:self.view];
        
        // world space coordinates
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, screenPos)];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        
        if (!object) break;
        if (object->type == [_circuit getProcessById:@"in"]) {
            // Toggle a switch:
            hit = YES;
            object->out = !object->out;
            [_circuit didUpdateObject:object];
        }
    }
    if (!hit && sender.numberOfTouches == 1) {
        // hit the background or only hit gates which don't have any tap action.
        // toggle the toolbelt (it animates)
        self.hud.toolbelt.visible = !self.hud.toolbelt.visible;
    }
    [self unpause];
}



#pragma mark -  UIResponder methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // cancel momentum
    [self stopPanAnimation];
    [self unpause];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {

}

@end
