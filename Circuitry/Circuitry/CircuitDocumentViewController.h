//
//  CircuitDocumentViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircuitDocument.h"

@interface CircuitDocumentViewController : UIViewController

// Container views:
@property (weak, nonatomic) IBOutlet UIView *objectListView;
@property (weak, nonatomic) IBOutlet UIView *problemInfoView;

// Document bindings:
- (void) setDocument:(CircuitDocument *) document;
@end
