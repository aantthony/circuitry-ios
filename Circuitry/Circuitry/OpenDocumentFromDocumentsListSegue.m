//
//  OpenDocumentFromDocumentsListSegue.m
//  Circuitry
//
//  Created by Anthony Foster on 8/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "OpenDocumentFromDocumentsListSegue.h"
#import "CircuitListViewController.h"

@implementation OpenDocumentFromDocumentsListSegue
- (void) perform {
//    return [super perform];
    CircuitListViewController *source = (CircuitListViewController *) self.sourceViewController;
    
    
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add the destination view as a subview, temporarily
    [sourceViewController.view addSubview:destinationViewController.view];
    
    // Transformation start scale
    destinationViewController.view.transform = CGAffineTransformMakeScale(0.05, 0.05);
    
    // Store original centre point of the destination view
    CGPoint originalCenter = destinationViewController.view.center;
    // Set center to start point of the button
    destinationViewController.view.center = CGPointMake(self.originatingRect.origin.x + self.originatingRect.size.width / 2, self.originatingRect.origin.y + self.originatingRect.size.height / 2);
    
    [source.navigationController setNavigationBarHidden:YES animated:YES];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Grow!
                         destinationViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         destinationViewController.view.center = originalCenter;
                     }
                     completion:^(BOOL finished){
                         [destinationViewController.view removeFromSuperview]; // remove from temp super view
//                         [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL]; // present VC
                         [source.navigationController pushViewController:destinationViewController animated:NO];
                     }];
    
    
}
@end
