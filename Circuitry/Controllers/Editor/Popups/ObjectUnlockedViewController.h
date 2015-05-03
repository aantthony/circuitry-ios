#import "ToolbeltItem.h"

@protocol ObjectUnlockedViewControllerDelegate;

@interface ObjectUnlockedViewController : UIViewController
@property (nonatomic) ToolbeltItem *item;
@property (nonatomic, weak) id<ObjectUnlockedViewControllerDelegate> delegate;
@end

@protocol ObjectUnlockedViewControllerDelegate <NSObject>

@required
- (void) unlockedViewController:(UIViewController *)controller didFinish:(id) sender;

@end
