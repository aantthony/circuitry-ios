//
//  ProblemInfoViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 24/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ProblemInfoViewController.h"

#import "CircuitDocument.h"

@interface ProblemInfoViewController ()
@property (weak, nonatomic) IBOutlet UIView *congratsView;
@property (weak, nonatomic) IBOutlet UIImageView *upArrow;
@property (weak, nonatomic) CircuitDocument *document;
@end

@implementation ProblemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _congratsView.alpha = 0.0;
    _congratsView.hidden = YES;
    self.isMinimised = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
}
- (void) showProgressToNextLevelScreen {
    _congratsView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        _congratsView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}
- (IBAction)didTapProblemDescriptionToHide:(id)sender {
    [self.delegate problemInfoViewController:self requestToggleVisibility:sender];
}

- (void) setIsMinimised:(BOOL)isMinimised {
    _isMinimised = isMinimised;
    _upArrow.alpha = _isMinimised ? 1.0 : 0.0;
}

- (void) showProblemDescription {
    _congratsView.hidden = YES;
}

- (IBAction)continueButton:(id)sender {
    [self.delegate problemInfoViewController:self didPressContinueButton:sender];
}
@end
