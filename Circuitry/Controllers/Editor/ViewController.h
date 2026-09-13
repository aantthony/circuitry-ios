@class ImageAtlas;
@class CircuitDocument;
@class ToolbeltItem;
@class Viewport;
@protocol ViewControllerTutorialProtocol;
#import <UIKit/UIKit.h>
@interface ViewController : UIViewController <UIGestureRecognizerDelegate>

+ (ImageAtlas *) atlas;

@property (nonatomic) Viewport *viewport;
@property (nonatomic) CircuitDocument *document;
@property (nonatomic, readonly) UIBarButtonItem *undoBarButtonItem;
@property (nonatomic, readonly) UIBarButtonItem *redoBarButtonItem;
// Explicit simulation control, independent of the renderer’s idle state.
@property (nonatomic) BOOL simulationPaused;
- (void)stepClock;
@property (nonatomic, weak) id <ViewControllerTutorialProtocol> tutorialDelegate;

// Gesture events:
- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;
- (IBAction) handleDragGateGesture:(UIPanGestureRecognizer *)sender;
- (IBAction) handleCreateGateGesture:(UIPanGestureRecognizer *)sender;
- (IBAction) handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;
- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction) handleLongPressObject:(UILongPressGestureRecognizer *)sender;

- (void)layoutControlsInView:(UIView *)host bottomInset:(CGFloat)bottomInset leftInset:(CGFloat)leftInset;
- (void) update;

- (void) startCreatingObjectFromItem: (ToolbeltItem *) item;

- (UIImage *) snapshot;

@end




@protocol ViewControllerTutorialProtocol <NSObject>

- (void) viewControllerTutorial:(ViewController *)viewController didChange:(id)sender;
- (void) viewControllerTutorial:(ViewController *)viewController didTapBackground:(id)sender;

@end
