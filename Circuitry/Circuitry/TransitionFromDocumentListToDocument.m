//
//  TransitionFromDocumentListToDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 9/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TransitionFromDocumentListToDocument.h"

@implementation TransitionFromDocumentListToDocument


#pragma mark -
#pragma mark UIViewControllerContextTransitioning delegate


- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    NSLog(@"test");
    return 3.0;
}
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)ctx {
    UIView *containerView = ctx.containerView;
    
    UIViewController *fromViewController = [ctx viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [ctx viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
    [containerView insertSubview:toViewController.view aboveSubview:fromViewController.view];
    toViewController.view.transform = CGAffineTransformMakeScale(0.0, 0.0);
    
    [UIView animateWithDuration:[self transitionDuration:ctx]
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toViewController.view.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished){
                         [ctx completeTransition:finished];
                     }];    
}


@end
