//
//  ToolbeltItemTableViewCell.m
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ToolbeltItemTableViewCell.h"
@interface ToolbeltItemTableViewCell() 
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;
@end

@implementation ToolbeltItemTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void) configureForToolbeltItem:(ToolbeltItem *) toolbeltItem {
    if (!toolbeltItem.isAvailable) {
        _label.text = @"Locked";
        _subtitle.text = @"Complete more levels";
        _image.image = [UIImage imageNamed:@"lock"];
        return;
    }
    _label.text = toolbeltItem.name;
    _subtitle.text = toolbeltItem.subtitle;
    _image.image = toolbeltItem.image;
}
@end
