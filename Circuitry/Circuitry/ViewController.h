#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "ImageAtlas.h"
#import "CircuitDocument.h"

#import "ToolbeltItem.h"

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>

//@property (, nonatomic) GLKMatrix4 _modelViewProjectionMatrix;\

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;
- (IBAction)handleDragGateGesture:(UIPanGestureRecognizer *)sender;

- (IBAction)handleCreateGateGesture:(UIPanGestureRecognizer *)sender;

- (IBAction)handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender;

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender;

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
- (IBAction)handleLongPressObject:(UILongPressGestureRecognizer *)sender;

+ (EAGLContext *) context;
+ (ImageAtlas *) atlas;

- (CircuitDocument *) document;
- (void) setDocument:(CircuitDocument *) document;

- (id) setup;
- (void)update;


- (void) startCreatingObjectFromItem: (ToolbeltItem *) item;

@end
