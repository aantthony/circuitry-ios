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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"openedBefore"]) {
        [self performSegueWithIdentifier:@"ShowTutorial" sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:TutorialViewController.class]) {
        TutorialViewController *vc = (TutorialViewController *) segue.destinationViewController;
        vc.delegate = self;
    }
}

- (void) tutorialViewController:(TutorialViewController *)tutorialViewController didFinishWithResult:(BOOL)result {
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"openedBefore"];
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
