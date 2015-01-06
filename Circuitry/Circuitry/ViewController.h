#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "ImageAtlas.h"
#import "CircuitDocument.h"

#import "ToolbeltItem.h"

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>

+ (EAGLContext *) context;
+ (ImageAtlas *) atlas;

@property (nonatomic) CircuitDocument *document;

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
