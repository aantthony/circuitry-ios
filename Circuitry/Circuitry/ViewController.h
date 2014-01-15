#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "ImageAtlas.h"

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>

//@property (, nonatomic) GLKMatrix4 _modelViewProjectionMatrix;\

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;
- (IBAction)handleDragGateGesture:(UIPanGestureRecognizer *)sender;

- (IBAction)handleCreateGateGesture:(UIPanGestureRecognizer *)sender;

- (IBAction)handleCreateLinkGesture:(UILongPressGestureRecognizer *)sender;

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;

- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender;

- (IBAction) handleLongPressGesture:(UILongPressGestureRecognizer *) recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
