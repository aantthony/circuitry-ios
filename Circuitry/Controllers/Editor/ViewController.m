#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>

#import "Viewport.h"
#import "CircuitDocument.h"
#import "DragGateGestureRecognizer.h"
#import "CreateGatePanGestureRecognizer.h"
#import "CreateLinkGestureRecognizer.h"
#import "LongPressObjectGesture.h"
#import "HoldDownGestureRecognizer.h"

#import "AppDelegate.h"

#import "ToolbeltItem.h"

static NSString * const tutorialFlagId = @"53c3cdc945f5603003000888";

@class ViewController;

@interface CircuitScene : SKScene
@property (nonatomic, weak) ViewController *viewController;
@end

@interface CircuitCanvasView : SKView
@property (nonatomic, weak) ViewController *viewController;
@end

@interface ViewController () {
    float beginGestureScale;
    
    CGVector beginLongPressGestureOffset;
    
    CGPoint panVelocity;
    
    BOOL isAnimatingScaleToSnap;
    BOOL toolbeltTouchIntercept;
    
    BOOL animatingPan;
    BOOL isPanning;
    
}
@property (nonatomic) NSArray *selectedObjects;
@property (nonatomic) CircuitScene *circuitScene;
@property (nonatomic) NSTimeInterval timeSinceLastUpdate;
@property (nonatomic) NSTimeInterval clockTickAccumulator;
@property (nonatomic) NSTimeInterval slowClockTickAccumulator;
@property (nonatomic) CFTimeInterval lastDisplayTimestamp;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) BOOL canPan;
@property (nonatomic) BOOL canZoom;
@property (nonatomic) BOOL isTutorial;
@property (nonatomic) UIImage *backgroundImage;
@property (nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, assign) CircuitObject *beginLongPressGestureObject;
@property (nonatomic, strong) CircuitNote *beginDragNote;
@property (nonatomic, strong) CircuitNote *beginResizeNote;
@property (nonatomic, assign) CircuitObject *holdDownGestureObject;

- (void)sceneDidUpdateAtTime:(NSTimeInterval)currentTime;

@end

@implementation CircuitCanvasView
@end

@implementation CircuitScene
- (void)update:(NSTimeInterval)currentTime {
    [self.viewController sceneDidUpdateAtTime:currentTime];
}
@end

@implementation ViewController

- (BOOL)circuitContainsClocks {
    if (!_document.circuit) return NO;

    __block BOOL containsClocks = NO;
    [_document.circuit enumerateClocksUsingBlock:^(CircuitObject *object, BOOL *stop) {
        containsClocks = YES;
        *stop = YES;
    }];
    return containsClocks;
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;

    // Clockless circuits can stop SpriteKit entirely while idle. Circuits with
    // clocks must keep receiving scene updates so their elapsed-time-driven
    // clock transitions continue to run.
    if (!paused) {
        self.circuitScene.paused = NO;
    } else if (![self circuitContainsClocks]) {
        self.circuitScene.paused = YES;
    }
}

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
    CGSize snapshotSize = self.view.bounds.size;
    if (snapshotSize.width <= 0.0 || snapshotSize.height <= 0.0) {
        return self.backgroundImage ?: [UIImage imageNamed:@"background.jpg"];
    }

    [_viewport updateSceneForViewSize:snapshotSize allowContentRebuild:YES];
    SKView *canvasView = (SKView *)self.view;
    SKTexture *snapshotTexture = [canvasView textureFromNode:self.circuitScene crop:self.circuitScene.frame];
    CGImageRef imageRef = snapshotTexture.CGImage;
    if (imageRef) {
        CGFloat imageScale = CGImageGetWidth(imageRef) / snapshotSize.width;
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:MAX(imageScale, 1.0) orientation:UIImageOrientationUp];
        CGImageRelease(imageRef);
        return image;
    }

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:snapshotSize];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [self.backgroundImage drawInRect:(CGRect){ CGPointZero, snapshotSize }];
    }];
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
+ (ImageAtlas *) atlas {
    static dispatch_once_t onceToken = 0;
    static ImageAtlas *atlas;
    
    dispatch_once(&onceToken, ^{
        atlas = [ImageAtlas imageAtlasWithName:@"circuit"];
    });
    
    return atlas;
}
- (ImageAtlas *) atlas {
    return ViewController.atlas;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    CircuitCanvasView *canvasView = (CircuitCanvasView *)self.view;
    canvasView.viewController = self;
    canvasView.contentMode = UIViewContentModeRedraw;

    _viewport = [[Viewport alloc] initWithAtlas:self.atlas];
    _backgroundImage = [UIImage imageNamed:@"background.jpg"];

    NSInteger maximumFramesPerSecond = UIScreen.mainScreen.maximumFramesPerSecond;
    canvasView.preferredFramesPerSecond = maximumFramesPerSecond;
    canvasView.ignoresSiblingOrder = YES;
    canvasView.shouldCullNonVisibleNodes = YES;
    self.circuitScene = [[CircuitScene alloc] initWithSize:canvasView.bounds.size];
    self.circuitScene.scaleMode = SKSceneScaleModeResizeFill;
    self.circuitScene.viewController = self;
    [_viewport attachToScene:self.circuitScene backgroundImage:_backgroundImage];
    
    self.document = _document;
    if (self.isTutorial) {
        [self configureTutorialGatesToPosition];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CircuitCanvasView *canvasView = (CircuitCanvasView *)self.view;
    CGSize viewSize = canvasView.bounds.size;
    if (!canvasView.window || !self.circuitScene || viewSize.width <= 0.0 || viewSize.height <= 0.0) return;

    // Storyboard views briefly retain their design-time size while a new
    // document controller is being installed in a resizable window. Prepare
    // the scene using the laid-out bounds before SpriteKit can display it.
    self.circuitScene.size = viewSize;
    [_viewport updateSceneForViewSize:viewSize allowContentRebuild:YES];
    if (canvasView.scene != self.circuitScene) {
        [canvasView presentScene:self.circuitScene];
    }
}

- (void) configureTutorialGatesToPosition {
    CircuitObject *A = [self.document.circuit findObjectById:@"53c3cdc945f5603003000000"];
    CircuitObject *B = [self.document.circuit findObjectById:@"53c3cdc945f5603003000888"];
    CircuitObject *andGate = [self.document.circuit findObjectById:@"53c3cdc945f56030030041aa"];
    CircuitObject *output = [self.document.circuit findObjectById:@"53c3cdc945f5603003000009"];
    BOOL isLandscape = self.view.frame.size.width > self.view.frame.size.height;
    if (!A || !B || !andGate || !output) {
        self.isTutorial = NO;
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
        self.isTutorial = NO;
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

- (NSUInteger)clockTransitionsForElapsedTime:(NSTimeInterval)elapsedTime
                                    interval:(NSTimeInterval)interval
                                 accumulator:(NSTimeInterval *)accumulator {
    *accumulator += elapsedTime;
    NSUInteger transitions = (NSUInteger)floor(*accumulator / interval);
    *accumulator -= transitions * interval;

    // Avoid an unbounded catch-up after a debugger pause or a badly delayed
    // frame while still preserving every transition during normal rendering.
    return MIN(transitions, 64);
}

- (BOOL)advanceClockProcess:(CircuitProcess *)process transitionCount:(NSUInteger)transitionCount {
    if (!_document.circuit || transitionCount == 0) return NO;

    __block BOOL containsMatchingClock = NO;
    [_document.circuit enumerateClocksUsingBlock:^(CircuitObject *object, BOOL *stop) {
        if (object->type == process) {
            containsMatchingClock = YES;
            *stop = YES;
        }
    }];
    if (!containsMatchingClock) return NO;

    for (NSUInteger transition = 0; transition < transitionCount; transition++) {
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            [self.document.circuit enumerateClocksUsingBlock:^(CircuitObject *object, BOOL *stop) {
                if (object->type == process) {
                    CircuitObjectSetOutput(internal, object, !object->out);
                }
            }];
        }];
        // Stateful components must observe every edge. The 512 steps are a
        // propagation limit for settling this edge, not additional clock ticks.
        [_document.circuit simulate:512];
    }
    return YES;
}

- (BOOL)advanceClocksByElapsedTime:(NSTimeInterval)elapsedTime {
    static const NSTimeInterval fastClockTransitionInterval = 0.005; // 100 Hz cycle
    static const NSTimeInterval slowClockTransitionInterval = 0.5;  // 1 Hz cycle

    NSTimeInterval fastAccumulator = self.clockTickAccumulator;
    NSUInteger fastTransitions = [self clockTransitionsForElapsedTime:elapsedTime
                                                              interval:fastClockTransitionInterval
                                                           accumulator:&fastAccumulator];
    self.clockTickAccumulator = fastAccumulator;

    NSTimeInterval slowAccumulator = self.slowClockTickAccumulator;
    NSUInteger slowTransitions = [self clockTransitionsForElapsedTime:elapsedTime
                                                              interval:slowClockTransitionInterval
                                                           accumulator:&slowAccumulator];
    self.slowClockTickAccumulator = slowAccumulator;

    BOOL changed = [self advanceClockProcess:&CircuitProcessClock transitionCount:fastTransitions];
    return [self advanceClockProcess:&CircuitProcessSlowClock transitionCount:slowTransitions] || changed;
}

#pragma mark - Drawing

- (void) updateTuturialState {
    if (!self.isTutorial) return;
    [self.tutorialDelegate viewControllerTutorial:self didChange:nil];
}

- (void)sceneDidUpdateAtTime:(NSTimeInterval)currentTime {
    if (self.lastDisplayTimestamp == 0) {
        self.lastDisplayTimestamp = currentTime;
    }
    self.timeSinceLastUpdate = currentTime - self.lastDisplayTimestamp;
    self.lastDisplayTimestamp = currentTime;

    if ([self advanceClocksByElapsedTime:self.timeSinceLastUpdate]) {
        [self unpause];
    }
    if (!self.isPaused) {
        [self update];
    }
    [_viewport updateSceneForViewSize:self.view.bounds.size allowContentRebuild:!isPanning && !animatingPan];
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
    // Tutorial:
    [self updateTuturialState];

    NSTimeInterval dt = self.timeSinceLastUpdate;

    if (!isAnimatingScaleToSnap && beginGestureScale != 0.0 && !_pinchGestureRecognizer.numberOfTouches) {
        isAnimatingScaleToSnap = YES;
    }

    if (isAnimatingScaleToSnap) {
        float lEnd = round(log2f(_viewport.zoomScale));
        if (lEnd > 2.0) lEnd = 2.0; // maximum zoom
        float lNow = log2f(_viewport.zoomScale);
        float k = 0.1;
        if (fabsf(lEnd - lNow) < 0.001) {
            k = 1.0;
            isAnimatingScaleToSnap = NO;
        }
        
        // TODO: this is a bit of a hack. Clean up the translate / scale math so that isn't so disgusting:
        CGPoint screenPos = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
        CGPoint aPos = [_viewport unproject: screenPos];
        _viewport.zoomScale = exp2f(lNow + (lEnd - lNow) * k);
        CGPoint bPos = [_viewport unproject: screenPos];
        
        // We want modelViewMatrix * curPos = newModelViewMatrix * curPos
        
        // A v = B v.. so what is B...
        [_viewport translateBy:CGVectorMake(_viewport.zoomScale * (bPos.x - aPos.x),
                                            _viewport.zoomScale * (bPos.y - aPos.y))];
        
    }
    
    [_viewport translateBy:CGVectorMake(panVelocity.x * dt, panVelocity.y * dt)];
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
    if (changes) {
        [_viewport setSceneContentNeedsUpdate];
    }
    if (isPanning || animatingPan || isAnimatingScaleToSnap || changes) {
        self.paused = NO;
    } else {
        self.paused = YES;
    }
}

// Faster one-part variant, called from within a rotating animation block, for additional animations during rotation.
// A subclass may override this method, or the two-part variants below, but not both.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration NS_AVAILABLE_IOS(3_0) {
    self.paused = NO;
    [_viewport setSceneContentNeedsUpdate];
}

- (void) checkError {
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
- (void) stopPanAnimation {
    panVelocity = CGPointZero;
    animatingPan = NO;
}

- (void) startCreatingObjectFromItem: (ToolbeltItem *) item {
    if ([item.type isEqualToString:@"note"]) {
        CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        center.x += (CGFloat)arc4random_uniform(121) - 60.0;
        center.y += (CGFloat)arc4random_uniform(121) - 60.0;
        CGPoint worldCenter = [self.viewport unproject:center];
        CircuitNote *note = [[CircuitNote alloc] initWithDictionary:@{
            @"text": @"Untitled note, hold to edit text",
            @"rect": @[@(worldCenter.x - 210.0), @(worldCenter.y - 110.0), @420.0, @220.0]
        }];
        [self.document.circuit.notes addObject:note];
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
        return;
    }

    Circuit *_circuit = _document.circuit;
    
    CGPoint locationInView = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        
    CGPoint position = [_viewport unproject:locationInView];
    
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
        CGPoint position = [_viewport unproject:[gestureRecognizer locationInView:self.view]];
        
        return [_viewport findCircuitObjectAtPosition:position] || [_viewport findNoteAtPosition:position];
    }
    
    if ([gestureRecognizer isKindOfClass:[HoldDownGestureRecognizer class]]) {
        CGPoint position = [_viewport unproject:[gestureRecognizer locationInView:self.view]];
        
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        if (!object) return NO;
        
        if (object->type != [_document.circuit getProcessById:@"pbtn"]) return NO;
        if (![_viewport isPosition:position onMomentaryButtonCap:object]) return NO;
        
        _holdDownGestureObject = object;
        
        return YES;
        
    }
    
    if ([gestureRecognizer isKindOfClass:[CreateLinkGestureRecognizer class]]) {
        // Create a link from a gate, or move a link that is connected to a gate
        
        CGPoint position = [_viewport unproject:[gestureRecognizer locationInView:self.view]];
        
        CircuitObject *o;
        // find the object under the touch:
        if ((o = [_viewport findCircuitObjectNearPosition:position])) {
            // calculate the offset (which will be used to determine which output to edit)
            CGVector offset = CGVectorMake(position.x - o->pos.x, position.y - o->pos.y);
            if (offset.dx < 150.0) {
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
        CGPoint position = [_viewport unproject:[recogniser locationInView:self.view]];
        // only accept long presses on circuit objects:
        CircuitNote *resizeNote = [_viewport findNoteResizeHandleAtPosition:position];
        if (resizeNote) {
            _beginResizeNote = resizeNote;
            return YES;
        }
        CircuitObject *o;
        if ((o = [_viewport findCircuitObjectAtPosition:position])) {
            _beginLongPressGestureObject = o;
            beginLongPressGestureOffset = CGVectorMake(_beginLongPressGestureObject->pos.x - position.x,
                                                       _beginLongPressGestureObject->pos.y - position.y);
            return YES;
        }
        CircuitNote *note = [_viewport findNoteAtPosition:position];
        if (note) {
            _beginDragNote = note;
            beginLongPressGestureOffset = CGVectorMake(note.frame.origin.x - position.x,
                                                       note.frame.origin.y - position.y);
            return YES;
        }
        // Dragging the background, defer this to the other pan gesture recognizer.
        return NO;
    } else if ([gestureRecognizer isKindOfClass:[CreateGatePanGestureRecognizer class]]) {
        // only starts if the finger is on the toolbelt
//        CGPoint location = [gestureRecognizer locationInView:self.view];
        return NO;
    } else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // drag view pan
        UIPanGestureRecognizer *recogniser = (UIPanGestureRecognizer *)gestureRecognizer;
        ;
        CGPoint position = [_viewport unproject:[recogniser locationInView:self.view]];
        if ([_viewport findCircuitObjectAtPosition:position] || [_viewport findNoteAtPosition:position]) {
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
    BOOL holdAndDrag = ([gestureRecognizer isKindOfClass:[HoldDownGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[DragGateGestureRecognizer class]]) ||
                       ([otherGestureRecognizer isKindOfClass:[HoldDownGestureRecognizer class]] && [gestureRecognizer isKindOfClass:[DragGateGestureRecognizer class]]);
    if (holdAndDrag) return YES;
    if ([gestureRecognizer isKindOfClass:[LongPressObjectGesture class]] || [otherGestureRecognizer isKindOfClass:[LongPressObjectGesture class]]) {
        return YES;
    }
    return NO;
}

- (IBAction)handleLongPressObject:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint position = [_viewport unproject:[sender locationInView:self.view]];
        CircuitObject *object = [_viewport findCircuitObjectAtPosition:position];
        CircuitNote *note = object ? nil : [_viewport findNoteAtPosition:position];
        if (note) {
            CGRect rect = [_viewport rectForNote:note inView:self.view];
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Canvas Note" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Edit Text" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UIAlertController *edit = [UIAlertController alertControllerWithTitle:@"Edit Note" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [edit addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.text = note.text;
                    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                }];
                [edit addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [edit addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *saveAction) {
                    note.text = edit.textFields.firstObject.text ?: @"";
                    [self updateChangeCount:UIDocumentChangeDone];
                    [self unpause];
                }]];
                [self presentViewController:edit animated:YES completion:nil];
            }]];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.document.circuit.notes removeObject:note];
                [self updateChangeCount:UIDocumentChangeDone];
                [self unpause];
            }]];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            actionSheet.popoverPresentationController.sourceView = self.view;
            actionSheet.popoverPresentationController.sourceRect = rect;
            [self presentViewController:actionSheet animated:YES completion:nil];
            return;
        }
        if (!object) return;
        
        ToolbeltItem *item = [ToolbeltItem toolbeltItemWithType:[NSString stringWithUTF8String:object->type->id]];
        if (!item) return;
        
        _selectedObjects = @[[NSValue valueWithPointer:object]];
        CGRect rect = [_viewport rectForObject:object inView:self.view];

        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:item.fullName message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            __block NSString *failureMessage = nil;

            [self->_document.circuit performWriteBlock:^(CircuitInternal *internal) {
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
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:failureMessage preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            [self updateChangeCount:UIDocumentChangeDone];
        }]];
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        actionSheet.popoverPresentationController.sourceView = self.view;
        actionSheet.popoverPresentationController.sourceRect = rect;
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}

- (void) updateChangeCount:(UIDocumentChangeKind)change {
    if (self.document.isProblem) return;
    
    [self.document.circuit setViewCenterX:_viewport.translation.x viewCenterY:_viewport.translation.y];
    
    [self.document updateChangeCount:change];
}

- (void) unpause {
    self.paused = NO;
    [_viewport setSceneContentNeedsUpdate];
}

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    if (!_canPan) return;
    isPanning = recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged;
    CGPoint translation = [recognizer translationInView:self.view];
    [_viewport translateBy:CGVectorMake(translation.x, translation.y)];
    // this makes it so next time "handlePanGesture:" is called, translation will be relative to the last one. (ie. translation is a delta)
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // give it some momentum
        panVelocity = [recognizer velocityInView:self.view];
        animatingPan = YES;
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self stopPanAnimation];
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
    } else if (sender.state == UIGestureRecognizerStateEnded ||
               sender.state == UIGestureRecognizerStateCancelled ||
               sender.state == UIGestureRecognizerStateFailed) {
        _holdDownGestureObject = NULL;
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            CircuitObjectSetOutput(internal, object, 0);
        }];
        
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
    }
}

- (IBAction)handleDragGateGesture:(UIPanGestureRecognizer *)sender {
    if (!_beginLongPressGestureObject && !_beginDragNote && !_beginResizeNote) {
        return;
    }
    
    CircuitObject *object = _beginLongPressGestureObject;
    if (sender.state == UIGestureRecognizerStateBegan && object && object == _holdDownGestureObject) {
        _holdDownGestureObject = NULL;
        [_document.circuit performWriteBlock:^(CircuitInternal *internal) {
            CircuitObjectSetOutput(internal, object, 0);
        }];
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self updateChangeCount:UIDocumentChangeDone];
        if (_beginLongPressGestureObject && !self.document.isProblem) {
            [self snapObjectToGrid:_beginLongPressGestureObject];
        }
        [self unpause];
        _beginLongPressGestureObject = NULL;
        _beginDragNote = nil;
        _beginResizeNote = nil;
        return;
    } else if ([sender numberOfTouches] != 1) {
        sender.enabled = NO;
        sender.enabled = YES;
        [self updateChangeCount:UIDocumentChangeDone];
        [self unpause];
        _beginLongPressGestureObject = NULL;
        _beginDragNote = nil;
        _beginResizeNote = nil;
        return;
    }
    
    // world space position of touch:
    CGPoint curPos = [_viewport unproject:[sender locationOfTouch:0 inView:self.view]];

    if (_beginResizeNote) {
        CGRect frame = _beginResizeNote.frame;
        frame.size = CGSizeMake(MAX(120.0, curPos.x - frame.origin.x),
                                MAX(80.0, curPos.y - frame.origin.y));
        _beginResizeNote.frame = frame;
        [self unpause];
        return;
    }
    
    // This moves it so that the user can drag the gate from places other than the gates top left corner
    CGPoint newPos = CGPointMake(curPos.x + beginLongPressGestureOffset.dx,
                                 curPos.y + beginLongPressGestureOffset.dy);
    if (_beginDragNote) {
        CGRect frame = _beginDragNote.frame;
        frame.origin = CGPointMake(newPos.x, newPos.y);
        _beginDragNote.frame = frame;
        [self unpause];
        return;
    }
    object->pos.x = newPos.x;
    object->pos.y = newPos.y;
    [self unpause];
}

- (IBAction)handleCreateGateGesture:(UIPanGestureRecognizer *)sender {
    (void)sender;
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
    CGPoint curPos = [_viewport unproject:[sender locationOfTouch:0 inView:self.view]];

    CircuitObject *target;
    
    Viewport *viewport = _viewport;
    
    if ((target = [_viewport findCircuitObjectNearPosition:curPos])) {
        
        CGVector offset = CGVectorMake(curPos.x - target->pos.x, curPos.y - target->pos.y);
        int targetIndex = -1;
        if (target == _viewport.currentEditingLinkSource && offset.dx > 140.0) {
            
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
                    CircuitLink *newLink = CircuitLinkCreate(internal, self->_viewport.currentEditingLinkSource, viewport.currentEditingLinkSourceIndex, target, targetIndex);
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
    CGPoint screenPos = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginGestureScale = _viewport.zoomScale;
    }
    
    CGPoint aPos = [_viewport unproject: screenPos];
    _viewport.zoomScale = beginGestureScale * recognizer.scale;
    CGPoint bPos = [_viewport unproject: screenPos];
    
    // We want modelViewMatrix * curPos = newModelViewMatrix * curPos (i.e., scaling should not translate the center point of the gesture)
    
    // A v = B v.. so what is B...
    [_viewport translateBy:CGVectorMake(_viewport.zoomScale * (bPos.x - aPos.x),
                                        _viewport.zoomScale * (bPos.y - aPos.y))];
    [self unpause];
    
////#define LOG_TEST 0
//#ifdef LOG_TEST
//    // the difference should be (0,0,0)
//    NSLog(@"((%.2f, %.2f : %.2f) , (%.2f, %.2f : %.2f))", aPos.x, cPos.x, aPos.x - cPos.x , aPos.y, cPos.y, aPos.y - cPos.y);
//#endif
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.circuitScene.paused = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.lastDisplayTimestamp = 0;
    self.clockTickAccumulator = 0;
    self.slowClockTickAccumulator = 0;
    self.circuitScene.paused = NO;
}

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender {
    BOOL hit = NO;

    for(int i = 0; i < sender.numberOfTouches; i++) {
        CGPoint screenPos = [sender locationOfTouch:i inView:self.view];
        
        // world space coordinates
        CGPoint position = [_viewport unproject:screenPos];
        
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
            if (object->type == [_document.circuit getProcessById:@"pbtn"]
                && [_viewport isPosition:position onMomentaryButtonCap:object]) {
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
