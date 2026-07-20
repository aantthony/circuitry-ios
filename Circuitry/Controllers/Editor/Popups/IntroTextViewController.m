#import "IntroTextViewController.h"

@interface IntroTextViewController ()
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *subtitleLabel;
@property (nonatomic, weak) UITextView *bodyTextView;
@property (nonatomic, weak) UIButton *button;
@end

@implementation IntroTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self findIntroViewsInView:self.view];
}

- (void)findIntroViewsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:UILabel.class]) {
            UILabel *label = (UILabel *)subview;
            if ([label.text isEqualToString:@"Hey There!"]) {
                self.titleLabel = label;
            } else if ([label.text isEqualToString:@"A QUICK INTRODUCTION"]) {
                self.subtitleLabel = label;
            }
        } else if ([subview isKindOfClass:UITextView.class]) {
            self.bodyTextView = (UITextView *)subview;
        } else if ([subview isKindOfClass:UIButton.class]) {
            self.button = (UIButton *)subview;
        }
        [self findIntroViewsInView:subview];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutIntroContent];
}

- (void)layoutIntroContent {
    if (!self.titleLabel || !self.subtitleLabel || !self.bodyTextView || !self.button) return;

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat contentWidth = MIN(width - 70.0, 480.0);
    CGFloat titleHeight = 48.0;
    CGFloat subtitleHeight = 24.0;
    CGFloat buttonHeight = 44.0;
    CGFloat titleGap = 28.0;
    CGFloat subtitleGap = 42.0;
    CGFloat buttonGap = 46.0;

    self.bodyTextView.textContainerInset = UIEdgeInsetsZero;
    self.bodyTextView.textContainer.lineFragmentPadding = 0.0;

    CGSize bodySize = [self.bodyTextView sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGFloat maxBodyHeight = height - titleHeight - subtitleHeight - buttonHeight - titleGap - subtitleGap - buttonGap - 80.0;
    CGFloat bodyHeight = MIN(ceil(bodySize.height), maxBodyHeight);

    CGFloat stackHeight = titleHeight + titleGap + subtitleHeight + subtitleGap + bodyHeight + buttonGap + buttonHeight;
    CGFloat y = MAX(28.0, floor((height - stackHeight) / 2.0));
    CGFloat x = floor((width - contentWidth) / 2.0);

    self.titleLabel.frame = CGRectMake(x, y, contentWidth, titleHeight);
    y += titleHeight + titleGap;

    self.subtitleLabel.frame = CGRectMake(x, y, contentWidth, subtitleHeight);
    y += subtitleHeight + subtitleGap;

    self.bodyTextView.frame = CGRectMake(x, y, contentWidth, bodyHeight);
    y += bodyHeight + buttonGap;

    CGFloat buttonWidth = MIN(contentWidth, 240.0);
    self.button.frame = CGRectMake(floor((width - buttonWidth) / 2.0), y, buttonWidth, buttonHeight);
}

- (IBAction)didTapButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
