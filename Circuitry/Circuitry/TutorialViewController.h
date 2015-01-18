//
//  TutorialViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 9/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@protocol TutorialViewControllerDelegate;

@interface TutorialViewController : UIViewController

@property (weak, nonatomic) id <TutorialViewControllerDelegate> delegate;
@end

@protocol TutorialViewControllerDelegate <NSObject>

- (void) tutorialViewController: (TutorialViewController*) tutorialViewController didFinishWithResult:(BOOL) result;

@end
