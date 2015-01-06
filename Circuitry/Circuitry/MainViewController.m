//
//  MainViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 24/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "MainViewController.h"
#import "TutorialViewController.h"

@interface MainViewController () <TutorialViewControllerDelegate>
@end

@implementation MainViewController

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
//    return UIStatusBarStyleLightContent;
}

static NSString *kDefaultsOpenedBefore = @"openedBefore";

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    static BOOL hasOpenedBefore = NO;
    if (!hasOpenedBefore && ![NSUserDefaults.standardUserDefaults boolForKey:kDefaultsOpenedBefore]) {
        hasOpenedBefore = YES;
        [self performSegueWithIdentifier:@"ShowTutorial" sender:self];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:TutorialViewController.class]) {
        TutorialViewController *vc = (TutorialViewController *) segue.destinationViewController;
        vc.delegate = self;
    }
}

- (void) tutorialViewController:(TutorialViewController *)tutorialViewController didFinishWithResult:(BOOL)result {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:kDefaultsOpenedBefore];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
