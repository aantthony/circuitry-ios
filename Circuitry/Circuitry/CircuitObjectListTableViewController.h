//
//  CircuitObjectListTableViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircuitDocument.h"

@interface CircuitObjectListTableViewController : UITableViewController
- (void) setDocument: (CircuitDocument *) document;
@end
