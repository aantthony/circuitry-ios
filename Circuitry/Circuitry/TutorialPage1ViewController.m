//
//  TutorialPage1ViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 19/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialPage1ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TutorialPage1ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;

@end

@implementation TutorialPage1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _descriptionText.layer.shadowColor = [[UIColor blackColor] CGColor];
    _descriptionText.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    _descriptionText.layer.shadowRadius = 1.0;
    _descriptionText.layer.shadowOpacity = 0.8;
    _descriptionText.layer.masksToBounds = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
