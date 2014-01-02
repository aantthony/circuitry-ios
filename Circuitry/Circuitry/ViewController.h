#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController <UIGestureRecognizerDelegate>


- (IBAction) handlePanGesture:(UIPanGestureRecognizer *) recognizer;

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *) recognizer;

- (IBAction) handleLongPressGesture:(UILongPressGestureRecognizer *) recognizer;

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
