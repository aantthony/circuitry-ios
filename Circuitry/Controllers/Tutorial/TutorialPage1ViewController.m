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

@end
