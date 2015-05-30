@class Circuit;
@protocol ProblemInfoViewControllerDelegate;

@interface ProblemInfoViewController : UIViewController
@property (nonatomic, weak) id <ProblemInfoViewControllerDelegate> delegate;
@property (nonatomic) BOOL isMinimised;
@property (nonatomic, readonly) Circuit *circuit;
- (void) showProgressToNextLevelScreen;
- (void) showProblemDescription;
@end


@protocol ProblemInfoViewControllerDelegate <NSObject>
@required
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id) sender;
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController requestToggleVisibility:(id)sender;
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController willToggleVisibility:(id)sender;
@end