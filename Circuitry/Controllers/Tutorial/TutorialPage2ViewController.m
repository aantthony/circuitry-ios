//
//  TutorialPage2ViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 19/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialPage2ViewController.h"

@interface TutorialPage2ViewController ()
@property (nonatomic, weak) UIImageView *deviceImageView;
@property (nonatomic, weak) UILabel *descriptionLabel;
@property (nonatomic, weak) UIView *descriptionContainer;

@end

@implementation TutorialPage2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self findTutorialViewsInView:self.view];
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.descriptionLabel.numberOfLines = 0;
}

- (void)findTutorialViewsInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if (!self.deviceImageView && [subview isKindOfClass:UIImageView.class]) {
            self.deviceImageView = (UIImageView *)subview;
        } else if (!self.descriptionLabel && [subview isKindOfClass:UILabel.class]) {
            self.descriptionLabel = (UILabel *)subview;
            self.descriptionContainer = subview.superview;
        }
        [self findTutorialViewsInView:subview];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutTutorialContent];
}

- (void)layoutTutorialContent {
    if (!self.deviceImageView || !self.descriptionLabel || !self.descriptionContainer) return;

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat margin = height < 700 ? 24.0 : 45.0;
    CGFloat gap = height < 700 ? 18.0 : 33.0;
    CGFloat textAreaHeight = MAX(150.0, height * 0.30);
    CGFloat maxImageHeight = height - margin - gap - textAreaHeight;
    CGFloat imageWidth = MIN(width * 0.70, maxImageHeight * 0.842);
    CGFloat imageHeight = imageWidth / 0.842;

    self.deviceImageView.frame = CGRectMake((width - imageWidth) / 2.0, margin, imageWidth, imageHeight);

    CGFloat containerY = CGRectGetMaxY(self.deviceImageView.frame) + gap;
    self.descriptionContainer.frame = CGRectMake(0, containerY, width, height - containerY);

    CGFloat labelWidth = MIN(width - 64.0, 520.0);
    CGFloat fontSize = height < 700 ? 20.0 : 24.0;
    self.descriptionLabel.font = [UIFont fontWithName:@"Avenir-Book" size:fontSize] ?: [UIFont systemFontOfSize:fontSize];

    CGSize maxLabelSize = CGSizeMake(labelWidth, self.descriptionContainer.bounds.size.height - 20.0);
    CGRect textRect = [self.descriptionLabel.text boundingRectWithSize:maxLabelSize
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName: self.descriptionLabel.font}
                                                               context:nil];
    CGFloat labelHeight = MIN(ceil(textRect.size.height), maxLabelSize.height);
    self.descriptionLabel.frame = CGRectMake((width - labelWidth) / 2.0,
                                             (self.descriptionContainer.bounds.size.height - labelHeight) / 2.0,
                                             labelWidth,
                                             labelHeight);
    self.descriptionLabel.preferredMaxLayoutWidth = labelWidth;
}

@end
