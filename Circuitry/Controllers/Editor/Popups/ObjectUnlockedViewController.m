#import "ObjectUnlockedViewController.h"

@interface ObjectUnlockedViewController()
@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UIImageView *itemImage;

@end
@implementation ObjectUnlockedViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    _itemImage.image = _item.image;
    _itemTitle.text = _item.fullName;
    
    _itemImage.alpha = 0.0;
    _itemTitle.alpha = 0.0;
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.itemImage.alpha = 1.0;
        self.itemTitle.alpha = 1.0;
    }];
}

- (IBAction)didTapButton:(id)sender {
    [self.delegate unlockedViewController:self didFinish:sender];
}

- (void) setItem:(ToolbeltItem *)item {
    _item = item;
}

@end
