//
//  CircuitObjectListTableViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@class ToolbeltItem;
@class Circuit;

@protocol CircuitObjectListTableViewControllerDelegate;

@interface CircuitObjectListTableViewController : UITableViewController
@property (nonatomic) Circuit *circuit;
@property (nonatomic, weak) id<CircuitObjectListTableViewControllerDelegate> delegate;
@end

@protocol CircuitObjectListTableViewControllerDelegate <NSObject>

- (void) tableViewController:(CircuitObjectListTableViewController *) tableViewController didStartCreatingObject:(ToolbeltItem *)item;

@end