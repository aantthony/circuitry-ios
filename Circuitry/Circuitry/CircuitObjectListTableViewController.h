//
//  CircuitObjectListTableViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircuitDocument.h"

#import "ToolbeltItem.h"

@protocol CircuitObjectListTableViewControllerDelegate;

@interface CircuitObjectListTableViewController : UITableViewController
- (void) setDocument: (CircuitDocument *) document;
@property (nonatomic, weak) id<CircuitObjectListTableViewControllerDelegate> delegate;
@end

@protocol CircuitObjectListTableViewControllerDelegate <NSObject>

- (void) tableViewController:(CircuitObjectListTableViewController *) tableViewController didStartCreatingObject:(ToolbeltItem *)item;

@end