//
//  TutorialPage3ViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 19/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "TutorialPage3ViewController.h"

@interface TutorialPage3ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;

@end

@implementation TutorialPage3ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _descriptionText.layer.shadowColor   = [[UIColor blackColor] CGColor];
    _descriptionText.layer.shadowOffset  = CGSizeMake(0.0, 1.0);
    _descriptionText.layer.shadowRadius  = 2.0;
    _descriptionText.layer.shadowOpacity = 1.0;
    _descriptionText.layer.masksToBounds = NO;
}

@end
