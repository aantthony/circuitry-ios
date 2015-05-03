//
//  CircuitCollectionViewCell.m
//  Circuitry
//
//  Created by Anthony Foster on 8/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitCollectionViewCell.h"
@interface CircuitCollectionViewCell()
@property (nonatomic, weak) UIView *highlightView;
@end
@implementation CircuitCollectionViewCell

- (void) awakeFromNib {
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.contentView.opaque = YES;
    self.backgroundView.opaque = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
    self.textLabel.layer.shadowRadius = 2.0;
    self.textLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.textLabel.layer.shadowOpacity = 1.0;
    self.textLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.textLabel.clipsToBounds = NO;
    self.textLabel.layer.shouldRasterize = YES;
    UIView *h = [[UIView alloc] initWithFrame:self.imageView.frame];
    h.backgroundColor = [UIColor whiteColor];
    h.alpha = 0.4;
    h.hidden = YES;
    [self.imageView.superview addSubview:h];
    self.highlightView = h;
}

- (void) setRounded:(BOOL)rounded {
    if (rounded == _rounded) return;
    _rounded = rounded;
    if (rounded) {
        self.imageView.layer.cornerRadius = 8.0;
        self.highlightView.layer.cornerRadius = 8.0;
        self.imageView.layer.borderWidth = 4.0;
        self.imageView.clipsToBounds = YES;
    } else {
        self.imageView.layer.cornerRadius = 0.0;
        self.highlightView.layer.cornerRadius = 0.0;
        self.imageView.layer.borderWidth = 4.0;
        self.imageView.clipsToBounds = NO;
    }
}

- (void) setShowingWhiteHighlight:(BOOL) show {
    self.highlightView.hidden = !show;
}

- (void) setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    BOOL showHighlight = (self.selected || self.highlighted) && self.enabled;
    [self setShowingWhiteHighlight:showHighlight];
}

- (void) setSelected:(BOOL)selected {
    [super setSelected:selected];
    BOOL showHighlight = (self.selected || self.highlighted) && self.enabled;
    [self setShowingWhiteHighlight:showHighlight];
}

@end
