@class CircuitDocument;
@protocol ProblemInfoViewControllerDelegate;

@interface ProblemInfoViewController : UIViewController
@property (nonatomic, weak) id <ProblemInfoViewControllerDelegate> delegate;
@property (nonatomic) BOOL isMinimised;
- (void) setDocument: (CircuitDocument *) document;
- (void) showProgressToNextLevelScreen;
- (void) showProblemDescription;
@end


@protocol ProblemInfoViewControllerDelegate <NSObject>
@required
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id) sender;
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController requestToggleVisibility:(id)sender;

@end