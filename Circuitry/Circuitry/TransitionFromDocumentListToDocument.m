//
//  TransitionFromDocumentListToDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 9/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TransitionFromDocumentListToDocument.h"

@implementation TransitionFromDocumentListToDocument

- (id) init {
    self = [super init];
    _reverse = NO;
    _fadeIn = NO;
    return self;
}

#pragma mark -
#pragma mark UIViewControllerContextTransitioning delegate

CGPoint CGRectGetMid(CGRect rect) {
    return CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
}
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)ctx {
    UIView *containerView = ctx.containerView;
    
    UIViewController *fromViewController = [ctx viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [ctx viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (_reverse) {
        [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
        float scale =  _originatingRect.size.width / toViewController.view.frame.size.width;
        [UIView animateWithDuration:[self transitionDuration:ctx] animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(scale, scale);
            fromViewController.view.center = CGRectGetMid(_originatingRect);
            fromViewController.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [ctx completeTransition:YES];
        }];
    } else {
        [containerView insertSubview:toViewController.view aboveSubview:fromViewController.view];
        CGPoint targetCenter = toViewController.view.center;
        toViewController.view.center = CGRectGetMid(_originatingRect);
        float scale =  _originatingRect.size.width / toViewController.view.frame.size.width;
        toViewController.view.transform = CGAffineTransformMakeScale(scale, scale);
        if (_fadeIn) {
            toViewController.view.alpha = 0.0;
        }
        toViewController.view.alpha = 0.0;
        [UIView animateWithDuration:[self transitionDuration:ctx]
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             toViewController.view.transform = CGAffineTransformIdentity;
                             toViewController.view.center = targetCenter;
//                             if (_fadeIn) {
                                 toViewController.view.alpha = 1.0;
//                             }
                         } completion:^(BOOL finished){
                             [ctx completeTransition:finished];
                         }];  
    }
      
}


@end
