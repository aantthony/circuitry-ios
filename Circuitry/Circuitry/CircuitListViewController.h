//
//  CircuitListControllerViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 7/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@interface CircuitListViewController : UICollectionViewController <UINavigationControllerDelegate>

- (IBAction) didChangeCircuitsProblemsSegment:(UISegmentedControl *)sender;
- (IBAction) didLongPress:(id)sender;
- (IBAction) createDocument:(id)sender;

@end
