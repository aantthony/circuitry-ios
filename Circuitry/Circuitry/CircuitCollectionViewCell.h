//
//  CircuitCollectionViewCell.h
//  Circuitry
//
//  Created by Anthony Foster on 8/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircuitListImageView.h"

@interface CircuitCollectionViewCell : UICollectionViewCell
@property (nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic) IBOutlet CircuitListImageView *imageView;
@end
