//
//  TutorialViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 9/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TutorialViewControllerDelegate;

@interface TutorialViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) id <TutorialViewControllerDelegate> delegate;
@end

@protocol TutorialViewControllerDelegate <NSObject>

- (void) tutorialViewController: (TutorialViewController*) tutorialViewController didFinishWithResult:(BOOL) result;

@end
