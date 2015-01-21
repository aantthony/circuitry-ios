//
//  CircuitCollectionViewCell.m
//  Circuitry
//
//  Created by Anthony Foster on 8/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitCollectionViewCell.h"

@implementation CircuitCollectionViewCell

- (void) awakeFromNib {
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.contentView.opaque = YES;
    self.backgroundView.opaque = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
}

- (void) setRounded:(BOOL)rounded {
    if (rounded == _rounded) return;
    if (rounded) {
        self.imageView.layer.cornerRadius = 8.0;
        self.imageView.layer.borderWidth = 4.0;
        self.imageView.clipsToBounds = YES;
    } else {
        self.imageView.layer.cornerRadius = 0.0;
        self.imageView.layer.borderWidth = 0.0;
        self.imageView.clipsToBounds = NO;
    }
}



@end
