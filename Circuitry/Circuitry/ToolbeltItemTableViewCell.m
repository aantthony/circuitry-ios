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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void) configureForToolbeltItem:(ToolbeltItem *) toolbeltItem {
    _label.text = toolbeltItem.name;
    _subtitle.text = toolbeltItem.subtitle;
    _image.image = toolbeltItem.image;
}
@end
