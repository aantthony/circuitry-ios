#import "ViewController.h"

#import "Viewport.h"
#import "CircuitDocument.h"
#import "Sprite.h"
#import "DragGateGestureRecognizer.h"
#import "CreateGatePanGestureRecognizer.h"
#import "CreateLinkGestureRecognizer.h"
#import "LongPressObjectGesture.h"
#import "HoldDownGestureRecognizer.h"

#import "AppDelegate.h"

#import "ToolbeltItem.h"

// For iOS 8 support:
#import <OpenGLES/ES1/glext.h>

static NSString * const tutorialFlagId = @"53c3cdc945f5603003000888";

@interface ViewController () <UIActionSheetDelegate> {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    GLKMatrixStackRef _stack;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    float beginGestureScale;
    
    GLKVector3 beginLongPressGestureOffset;
    
    CGPoint panVelocity;
    
    BOOL isAnimatingScaleToSnap;
    BOOL toolbeltTouchIntercept;
    
    CGPoint draggingOutFromToolbeltStart;
    
    BOOL animatingPan;
    
}
@property (nonatomic) NSArray *selectedObjects;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL canPan;
@property (nonatomic) BOOL canZoom;
@property (nonatomic) BOOL isTutorial;
@property (nonatomic) Sprite *bg;
@property (nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, assign) CircuitObject *beginLongPressGestureObject;
@property (nonatomic, assign) CircuitObject *holdDownGestureObject;

- (void)tearDownGL;

@end

@implementation ViewController

- (void) setDocument:(CircuitDocument *) document {
    _document = document;
    _viewport.document = _document;
    _canPan = YES;
    _canZoom = YES;
    NSString *tutorial = document.circuit.meta[@"tutorial"];
    _isTutorial = [tutorial isEqualToString:tutorialFlagId];
    if (_document.circuit.viewDetails) {
        NSNumber *num = _document.circuit.viewDetails[@"canPan"];
        if (num && !num.boolValue) {
            _canPan = NO;
        }
        num = _document.circuit.viewDetails[@"canZoom"];
        if (num && !num.boolValue) {
            _canZoom = NO;
        }
    }
    
    if (self.view) {
        [self update];
    }
}

- (UIImage*)snapshot
{
    [EAGLContext setCurrentContext:self.context];
    GLKView *view = (GLKView *)self.view;
    return view.snapshot;
    
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
//    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorRenderbuffer);
    [view bindDrawable];
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    [self checkError];
    GLint x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));

    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // Set the scale parameter to your OpenGL ES view's contentScaleFactor
    // so that you get a high-resolution snapshot when its value is greater than 1.0
    CGFloat scale = self.view.contentScaleFactor;
    widthInPoints = width / scale;
    heightInPoints = height / scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

-(void)appWillResignActive:(NSNotification*)note {
    if (_document.isProblem) return;
    
    if (_document.hasUnsavedChanges) {
        [_document useScreenshot: self.snapshot];
        
        [_document savePresentedItemChangesWithCompletionHandler:^(NSError *errorOrNil) {

        }];
    }
}

-(void)appWillTerminate:(NSNotification*)note {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}
+ (EAGLContext *) context {
    static dispatch_once_t onceToken = 0;
    static EAGLContext * context;
    
    dispatch_once(&onceToken, ^{
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    });
    
    return context;
}
+ (ImageAtlas *) atlas {
    static dispatch_once_t onceToken = 0;
    static ImageAtlas *atlas;
    
    dispatch_once(&onceToken, ^{
        atlas = [ImageAtlas imageAtlasWithName:@"circuit"];
    });
    
    return atlas;
}
- (EAGLContext *) context {
    return ViewController.context;
}
- (ImageAtlas *) atlas {
    return ViewController.atlas;
}
- (Sprite *) backgroundSprite {
    static id instance;
    if (instance) return instance;
    
    GLKTextureInfo *bgTexture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"background" withExtension:@"jpg"]];
    return instance = [[Sprite alloc] initWithTexture:bgTexture];
}

- (IBAction)group:(id)sender {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    panVelocity = CGPointMake(0.0, 0.0);
    
    isAnimatingScaleToSnap = NO;
    toolbeltTouchIntercept = NO;
    animatingPan = NO;
    beginGestureScale = 0.0;
    
    _stack = GLKMatrixStackCreate(NULL);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.view.layer;
    
    eaglLayer.opaque = TRUE;
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    [self checkError];
    glEnable(GL_DEPTH_TEST);
    
    [self checkError];
    
    _viewport = [[Viewport alloc] initWithContext:self.context atlas: self.atlas];
    
    [self checkError];
    
    _bg = self.backgroundSprite;
    
    self.document = _document;
    if (self.isTutorial) {
        [self configureTutorialGatesToPosition];
    }
}

- (void) configureTutorialGatesToPosition {
    CircuitObject *A = [self.document.circuit findObjectById:@"53c3cdc945f5603003000000"];
    CircuitObject *B = [self.document.circuit findObjectById:@"53c3cdc945f5603003000888"];
    CircuitObject *andGate = [self.document.circuit findObjectById:@"53c3cdc945f56030030041aa"];
    CircuitObject *output = [self.document.circuit findObjectById:@"53c3cdc945f5603003000009"];
    BOOL isLandscape = self.view.frame.size.width > self.view.frame.size.height;
    if (!A || !B || !andGate || !output) {
        NSParameterAssert(nil);
        return;
    }
    if (isLandscape) {
        A->pos.x = 0;
        A->pos.y = 0;
        B->pos.x = 0;
        B->pos.y = 400;
        andGate->pos.x = 700;
        andGate->pos.y = 200;
        output->pos.x = 1400;
        output->pos.y = 200;
    } else {
        A->pos.x = 0;
        A->pos.y = 0;
        B->pos.x = 0;
        B->pos.y = 800;
        andGate->pos.x = 500;
        andGate->pos.y = 400;
        output->pos.x = 1000;
        output->pos.y = 400;
    }
}

- (BOOL) animateTutorialObjectsToPosition {
    CircuitObject *A = [self.document.circuit findObjectById:@"53c3cdc945f5603003000000"];
    CircuitObject *B = [self.document.circuit findObjectById:@"53c3cdc945f5603003000888"];
    CircuitObject *andGate = [self.document.circuit findObjectById:@"53c3cdc945f56030030041aa"];
    CircuitObject *output = [self.document.circuit findObjectById:@"53c3cdc945f5603003000009"];
    if (!A || !B || !andGate || !output) {
        NSParameterAssert(nil);
        return NO;
    }
    BOOL isLandscape = self.view.frame.size.width > self.view.frame.size.height;
    BOOL changes = NO;
    if (isLandscape) {
        if (_beginLongPressGestureObject != A && animateGateToLockedPosition(A, 0, 0)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != B && animateGateToLockedPosition(B, 0, 400)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != andGate && animateGateToLockedPosition(andGate, 700, 200)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != output && animateGateToLockedPosition(output, 1400, 200)) {
            changes = YES;
        }
    } else {
        if (_beginLongPressGestureObject != A && animateGateToLockedPosition(A, 0, 0)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != B && animateGateToLockedPosition(B, 0, 800)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != andGate && animateGateToLockedPosition(andGate, 500, 400)) {
            changes = YES;
        }
        if (_beginLongPressGestureObject != output && animateGateToLockedPosition(output, 1000, 400)) {
            changes = YES;
        }
    }
    return changes;
}

- (void) timerTick:(id) sender {
    if (!_document.circuit) return;
    static int d = 0;
    d++;
    if (d > 100) d = 0;
    __block int clocks = 0;
    [self.document.circuit performWriteBlock:^(CircuitInternal *internal) {
        [self.document.circuit enumerateClocksUsingBlock:^(CircuitObject *object, BOOL *stop) {
            clocks++;
            CircuitObjectSetOutput(internal, object, !object->out);
        }];
    }];
    
    if (clocks) {
        [self unpause];
    }
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    [self checkError];
//    glDeleteBuffers(1, &_vertexBuffer);
//    glDeleteVertexArraysOES(1, &_vertexArray);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void) updateTuturialState {
    if (!self.isTutorial) return;
    [self.tutorialDelegate viewControllerTutorial:self didChange:nil];
}

static BOOL animateGateToLockedPosition(CircuitObject *object, float x, float y) {
    float dx = object->pos.x - x;
    float dy = object->pos.y - y;
    float d2 = dx * dx + dy * dy;
    if (d2 == 0.0) {
        return NO;
    }
    if (d2 <= 0.01 && d2 >= -0.01) {
        object->pos.x = x;
        object->pos.y = y;
    }
    float k = 0.05;
    object->pos.x -= k * dx;
    object->pos.y -= k * dy;
    return YES;
}

- (void)update
{
    [self checkError];
    
    // Tutorial:
    [self updateTuturialState];
    
    // time differnce in seconds (float)
    NSTimeInterval dt = self.timeSinceLastUpdate;
    
//    float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    CGRect boundary = self.view.bounds;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0.0, boundary.size.width, boundary.size.height, 0.0, -10.0, 10.0);
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
        isAnimatingScaleToSnap = YES;
    }

    if (isAnimatingScaleToSnap) {
        float lEnd = round(log2f(_viewport.scaleWithFloat));
        if (lEnd > 2.0) lEnd = 2.0; // maximum zoom
        float lNow = log2f(_viewport.scaleWithFloat);
        float k = 0.1;
        if (fabsf(lEnd - lNow) < 0.001) {
            k = 1.0;
            isAnimatingScaleToSnap = NO;
        }
        
        // TODO: this is a bit of a hack. Clean up the translate / scale math so that isn't so disgusting:
        CGPoint screenPos = PX(self.view.contentScaleFactor, CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2));
        GLKVector3 aPos = [_viewport unproject: screenPos];
        _viewport.scaleWithFloat = exp2f(lNow + (lEnd - lNow) * k);
        GLKVector3 bPos = [_viewport unproject: screenPos];
        
        // We want modelViewMatrix * curPos = newModelViewMatrix * curPos
        
        // A v = B v.. so what is B...
        [_viewport translate: GLKVector3Make(_viewport.scaleWithFloat * (bPos.x - aPos.x), _viewport.scaleWithFloat * (bPos.y - aPos.y), 0.0)];
        
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
    
    if (_isTutorial) {
        if ([self animateTutorialObjectsToPosition]) {
            changes++;
        }
    }
    
    int circuitChanges = [_document.circuit simulate:512];
    changes += circuitChanges;
    changes += [_viewport update: dt];
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


static CGFloat gridSize = 33.0;

- (void) snapObjectsToGrid {
    [self.document.circuit performWriteBlock:^(CircuitInternal *internal) {
        [self.document.circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
            CGFloat x = object->pos.x;
            CGFloat y = object->pos.y;
            x = roundf(x / gridSize) * gridSize;
            y = roundf(y / gridSize) * gridSize;
            object->pos.x = x;
            object->pos.y = y;
        }];
    }];
    [self unpause];
}

- (void) snapObjectToGrid:(CircuitObject *)object {
    [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
        CGFloat x = object->pos.x;
        CGFloat y = object->pos.y;
        x = roundf(x / gridSize) * gridSize;
        y = roundf(y / gridSize) * gridSize;
        object->pos.x = x;
        object->pos.y = y;
    }];
    [self unpause];
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self checkError];
    glClearColor(0.4, 0.4, 0.4, 1.0f);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glDisable(GL_DEPTH_TEST);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    [self checkError];
    GLKMatrixStackLoadMatrix4(_stack, _modelViewProjectionMatrix);
    [_bg drawWithSize:GLKVector2Make(rect.size.width, rect.size.height) withTransform:_modelViewProjectionMatrix];
    [self checkError];
    [_viewport drawWithStack:_stack];
    [self checkError];
}

// Take a pt screen coordinate and translate it to pixel screen coordinates, because OpenGL only deals with pixels.
CGPoint PX(float contentScaleFactor, CGPoint pt) {
    return CGPointMake(contentScaleFactor * pt.x, contentScaleFactor * pt.y);
}

- (void) stopPanAnimation {
    panVelocity = CGPointZero;
    animatingPan = NO;
}

- (void) startCreatingObjectFromItem: (ToolbeltItem *) item {
    Circuit *_circuit = _document.circuit;
    
    CGPoint locationInView = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        
    GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, locationInView)];
    
    position.x += (float)(arc4random_uniform(200)) - 100.0;
    position.y += (float)(arc4random_uniform(200)) - 100.0;
    
    CircuitProcess *process = [_circuit getProcessById:item.type];
    
    [_circuit performWriteBlock:^(CircuitInternal *internal) {
        CircuitObject *o = CircuitObjectCreate(internal, process);
        o->id = [MongoID id];
        o->pos.x = position.x;
        o->pos.y = position.y;
        
        self.beginLongPressGestureObject = o;
    }];
    
    [self unpause];

}

#pragma mark -  Gesture methods


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    [self unpause];
    [self stopPanAnimation];
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        isAnimatingScaleToSnap = NO;
        return YES;
	}
    
    if ([gestureRecognizer isKindOfClass:[LongPressObjectGesture class]]) {
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [gestureRecognizer locationInView:self.view])];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        if (!object) return NO;
        
        return YES;
    }
    
    if ([gestureRecognizer isKindOfClass:[HoldDownGestureRecognizer class]]) {
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [gestureRecognizer locationInView:self.view])];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        if (!object) return NO;
        
        if (object->type != [_document.circuit getProcessById:@"pbtn"]) return NO;
        
        _holdDownGestureObject = object;
        
        return YES;
        
    }
    
    if ([gestureRecognizer isKindOfClass:[CreateLinkGestureRecognizer class]]) {
        // Create a link from a gate, or move a link that is connected to a gate
        
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, [gestureRecognizer locationInView:self.view])];
        
        CircuitObject *o;
        // find the object under the touch:
        if ((o = [_viewport findCircuitObjectNearPosition:position])) {
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
                [_viewport didBeginCreatingLink:o outletIndex:index];
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
            _beginLongPressGestureObject = o;
            GLKVector3 objectPosition = *(GLKVector3 *) &_beginLongPressGestureObject->pos;
            beginLongPressGestureOffset = GLKVector3Subtract(objectPosition, position);
            return YES;
        }
        // Dragging the background, defer this to the other pan gesture recognizer.
        return NO;
    } else if ([gestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]]) {
        // only starts if the finger is on the toolbelt
//        CGPoint location = [gestureRecognizer locationInView:self.view];
//        if (!CGRectContainsPoint(_hud.toolbelt.bounds, location)) {
            return NO;
//        }
        
        CGPoint p = [gestureRecognizer locationInView:self.view];
        p.x = 0.0;
        
//        int index = [_hud.toolbelt indexAtPosition:p];
//        if (index == -1) return NO;
//        _hud.toolbelt.currentObjectIndex = index;
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
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    if ([gestureRecognizer isKindOfClass:[LongPressObjectGesture class]] || [otherGestureRecognizer isKindOfClass:[LongPressObjectGesture class]]) {
        return YES;
    }
    return NO;
}

- (IBAction)handleLongPressObject:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        GLKVector3 position = [_viewport unproject:PX(self.view.contentScaleFactor, [sender locationInView:self.view])];
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        if (!object) return;
        
        ToolbeltItem *item = [ToolbeltItem toolbeltItemWithType:[NSString stringWithUTF8String:object->type->id]];
        if (!item) return;
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:item.fullName delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove" otherButtonTitles: nil];

        _selectedObjects = @[[NSValue valueWithPointer:object]];
        CGRect rect = [_viewport rectForObject:object inView:self.view];
        
        [actionSheet showFromRect:rect inView:self.view animated:YES];
        
    }
    
}

#pragma mark -
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        __block NSString *failureMessage = nil;
        
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            
            for(id obj in self.selectedObjects) {
                CircuitObject *object = [obj pointerValue];
                if (object->flags & CircuitObjectFlagLocked) {
                    failureMessage = @"This object cannot be removed.";
                    return;
                }
            }
            
            for(id obj in self.selectedObjects) {
                CircuitObject *object = [obj pointerValue];
                CircuitObjectRemove(internal, object);
                [self unpause];
            }
        }];
        if (failureMessage) {
            [[[UIAlertView alloc] initWithTitle:nil message:failureMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            return;
        }
        [self updateChangeCount:UIDocumentChangeDone];
    }
}

- (void) updateChangeCount:(UIDocumentChangeKind)change {
    if (self.document.isProblem) return;
    
    [self.document.circuit setViewCenterX:_viewport.translate.x viewCenterY:_viewport.translate.y];
    
    [self.document updateChangeCount:change];
}

- (void) unpause {
    self.paused = NO;
}

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    if (!_canPan) return;
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
- (IBAction)handleHoldDownGesture:(UILongPressGestureRecognizer *)sender {
    
    CircuitObject *object = _holdDownGestureObject;
    if (!object) return;
    if (sender.state == UIGestureRecognizerStateBegan) {
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            if (object->out != 0) return;
            CircuitObjectSetOutput(internal, object, 1);
        }];
        
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        _holdDownGestureObject = NULL;
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            CircuitObjectSetOutput(internal, object, 0);
        }];
        
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
    }
}

- (IBAction)handleDragGateGesture:(UIPanGestureRecognizer *)sender {
    if (!_beginLongPressGestureObject) {
        return;
    }
    
    CircuitObject *object = _beginLongPressGestureObject;
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self updateChangeCount:UIDocumentChangeDone];
        if (_beginLongPressGestureObject && !self.document.isProblem) {
            [self snapObjectToGrid:_beginLongPressGestureObject];
        }
        [self unpause];
        _beginLongPressGestureObject = NULL;
        return;
    } else if ([sender numberOfTouches] != 1) {
        sender.enabled = NO;
        sender.enabled = YES;
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
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
//    Circuit *_circuit = _document.circuit;
//    if (draggingOutFromToolbeltLockY) {
//        // still dragging it out of the toolbelt
//        
//        if ([sender numberOfTouches] != 1) {
//            sender.enabled = NO;
//            sender.enabled = YES;
//            return;
//        }
//        CGPoint p = [sender locationOfTouch:0 inView:self.view];
//        
//        CGPoint diff = CGPointMake(p.x - draggingOutFromToolbeltStart.x, p.y - draggingOutFromToolbeltStart.y);
//        if (diff.x > _hud.toolbelt.listWidth) {
//            GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, p)];
//            
//            // the gate is out of the toolbelt, act the same as the normal drag gate gesture from now on:
//            draggingOutFromToolbeltLockY = NO;
//            
//            ToolbeltItem *item = _hud.toolbelt.items[_hud.toolbelt.currentObjectIndex];
//            
//            
//            // Create a new gate object, and start dragging the gate (as if the drag gate gesture recognizer started)
//            
//            CircuitObject *o = [_circuit addObject:item.type];
//            beginLongPressGestureObject = o;
//            o->pos.x = position.x;
//            o->pos.y = position.y - 100.0;
//            GLKVector3 objectPosition = *(GLKVector3 *) &beginLongPressGestureObject->pos;
//
//            beginLongPressGestureOffset = GLKVector3Subtract(objectPosition, position);
//            
//            beginLongPressGestureObject = o;
//            
//            _hud.toolbelt.currentObjectIndex = -1;
//        } else {
//            _hud.toolbelt.currentObjectX = diff.x;
//        }
//    } else {
//        // the gate is out of the toolbelt:
//        [self handleDragGateGesture:sender];
//    }
//    [self unpause];
}

- (IBAction)handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender {
    Circuit *_circuit = _document.circuit;
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        // If there is no active gate in creation, then just cancel.
        _viewport.currentEditingLinkSource = NULL;
        _viewport.currentEditingLinkTarget = NULL;
        [self unpause];

        [self updateChangeCount:UIDocumentChangeDone];
        
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
    
    Viewport *viewport = _viewport;
    
    if ((target = [_viewport findCircuitObjectNearPosition:curPos])) {
        
        GLKVector3 offset = GLKVector3Subtract(curPos, *(GLKVector3 *)&target->pos);
        int targetIndex = -1;
        if (target == _viewport.currentEditingLinkSource && offset.x > 140.0) {
            
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
                    [_circuit performWriteBlock:^(CircuitInternal *internal) {
                        CircuitLinkRemove(internal, viewport.currentEditingLink);
                        // It is going to change anyway, but to be consistent, this is now considered deleted.
                        viewport.currentEditingLink = NULL;
                    }];
                }
                // Create a new link and tell the viewport renderer that it is the one being edited:
                _viewport.currentEditingLinkTargetIndex = targetIndex;
                [_circuit performWriteBlock:^(CircuitInternal *internal) {
                    CircuitLink *newLink = CircuitLinkCreate(internal, _viewport.currentEditingLinkSource, viewport.currentEditingLinkSourceIndex, target, targetIndex);
                    viewport.currentEditingLink = newLink;
                }];
                [_viewport didAttachLink:_viewport.currentEditingLink];
            }
        }
        
        
    } else {
        // Couldn't find a gate under the touch, remove the link being dragged if one exists
        if (_viewport.currentEditingLink) {
            [_circuit performWriteBlock:^(CircuitInternal *internal) {
                CircuitLinkRemove(internal, viewport.currentEditingLink);
                viewport.currentEditingLink = NULL;
            }];
            [_viewport didDetachEditingLink];
            _viewport.currentEditingLinkTarget = NULL;
        }
    }
    // set the green wire to end at curPos (which is drawn by Viewport)
    _viewport.currentEditingLinkTargetPosition = curPos;
    [self unpause];
}

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    if (!_canZoom) {
        return;
    }
    // Zoom:
    CGPoint screenPos = PX(self.view.contentScaleFactor, [recognizer locationInView:self.view]);
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginGestureScale = _viewport.scaleWithFloat;
    }
    
    GLKVector3 aPos = [_viewport unproject: screenPos];
    _viewport.scaleWithFloat = beginGestureScale * recognizer.scale;
    GLKVector3 bPos = [_viewport unproject: screenPos];
    
    // We want modelViewMatrix * curPos = newModelViewMatrix * curPos (i.e., scaling should not translate the center point of the gesture)
    
    // A v = B v.. so what is B...
    [_viewport translate: GLKVector3Make(_viewport.scaleWithFloat * (bPos.x - aPos.x), _viewport.scaleWithFloat * (bPos.y - aPos.y), 0.0)];
    [self unpause];
    
////#define LOG_TEST 0
//#ifdef LOG_TEST
//    GLKVector3 cPos = [_viewport unproject: PX(self.view.contentScaleFactor, [recognizer locationInView:self.view])];
//    // the difference should be (0,0,0)
//    NSLog(@"((%.2f, %.2f : %.2f) , (%.2f, %.2f : %.2f))", aPos.x, cPos.x, aPos.x - cPos.x , aPos.y, cPos.y, aPos.y - cPos.y);
//#endif
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:0.005 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender {
    BOOL hit = NO;

    for(int i = 0; i < sender.numberOfTouches; i++) {
        CGPoint screenPos = [sender locationOfTouch:i inView:self.view];
        
        // world space coordinates
        GLKVector3 position = [_viewport unproject: PX(self.view.contentScaleFactor, screenPos)];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        
        if (!object) {
            [self.tutorialDelegate viewControllerTutorial:self didTapBackground:sender];
            break;
        }
        
        BOOL isButton = object->type == [_document.circuit getProcessById:@"button"];
        BOOL isInput = object->type == [_document.circuit getProcessById:@"in"];
        if (isButton || isInput) {
            // Toggle a switch:
            hit = YES;
            [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
                CircuitObjectSetOutput(internal, object, !object->out);
            }];
            [self updateChangeCount:UIDocumentChangeDone];
        } else {
            if (object->type == [_document.circuit getProcessById:@"pbtn"]) {
                hit = YES;
                [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
                    if (object->out != 0) return;
                    CircuitObjectSetOutput(internal, object, 1);
                }];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.document.circuit performWriteBlock:^(CircuitInternal *internal) {
                        CircuitObjectSetOutput(internal, object, 0);
                    }];
                    [self updateChangeCount:UIDocumentChangeDone];
                    [self unpause];
                });
            }
        }
    }
    if (!hit && sender.numberOfTouches == 1) {
        // hit the background or only hit gates which don't have any tap action.
        // toggle the toolbelt (it animates)
        [self toggleHeaderVisibility: sender];
    }
    [self unpause];
}

- (IBAction) toggleHeaderVisibility:(id)sender {
    BOOL visible = YES;
//    self.hud.toolbelt.visible = visible;
//    self.navigationController.navigationBarHidden = !visible;
    [UIView animateWithDuration:0.2 animations:^{
        self.navigationController.navigationBar.alpha = visible ? 1.0 : 0.0;
    }];
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
