#import <UIKit/UIKit.h>
#import "CircuitDocument.h"
@protocol ProblemInfoViewControllerDelegate;

@interface ProblemInfoViewController : UIViewController
@property (nonatomic, weak) id <ProblemInfoViewControllerDelegate> delegate;
- (void) setDocument: (CircuitDocument *) document;
- (void) showProgressToNextLevelScreen;
- (void) showProblemDescription;
@end


@protocol ProblemInfoViewControllerDelegate <NSObject>
@required
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id) sender;

@end