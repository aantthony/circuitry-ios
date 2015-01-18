#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "ImageAtlas.h"
#import "CircuitDocument.h"

#import "ToolbeltItem.h"
#import "Viewport.h"
@protocol ViewControllerTutorialProtocol;

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>

+ (EAGLContext *) context;
+ (ImageAtlas *) atlas;

@property (nonatomic) Viewport *viewport;
@property (nonatomic) CircuitDocument *document;
@property (nonatomic, weak) id <ViewControllerTutorialProtocol> tutorialDelegate;

// Gesture events:
- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;
- (IBAction) handleDragGateGesture:(UIPanGestureRecognizer *)sender;
- (IBAction) handleCreateGateGesture:(UIPanGestureRecognizer *)sender;
- (IBAction) handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender;
- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;
- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction) handleLongPressObject:(UILongPressGestureRecognizer *)sender;

// GLKViewController Protocol:
- (void) update;

- (void) startCreatingObjectFromItem: (ToolbeltItem *) item;

@end




@protocol ViewControllerTutorialProtocol <NSObject>

- (void) viewControllerTutorial:(ViewController *)viewController didChange:(id)sender;

@end
