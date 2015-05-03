//
//  CircuitObjectListTableViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@class CircuitDocument;
@class ToolbeltItem;

@protocol CircuitObjectListTableViewControllerDelegate;

@interface CircuitObjectListTableViewController : UITableViewController
- (void) setDocument: (CircuitDocument *) document;
@property (nonatomic, weak) id<CircuitObjectListTableViewControllerDelegate> delegate;
@end

@protocol CircuitObjectListTableViewControllerDelegate <NSObject>

- (void) tableViewController:(CircuitObjectListTableViewController *) tableViewController didStartCreatingObject:(ToolbeltItem *)item;

@end