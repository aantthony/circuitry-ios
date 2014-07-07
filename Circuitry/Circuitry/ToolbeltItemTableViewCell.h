//
//  ToolbeltItemTableViewCell.h
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToolbeltItem.h"
@interface ToolbeltItemTableViewCell : UITableViewCell
- (void) configureForToolbeltItem:(ToolbeltItem *) toolbeltItem;
@end
