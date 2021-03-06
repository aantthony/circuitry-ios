//
//  ProblemInfoViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 24/09/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ProblemInfoViewController.h"

#import "CircuitDocument.h"
#import "ProblemSetProblemInfo.h"

@interface ProblemInfoViewController ()
@property (weak, nonatomic) IBOutlet UIView *congratsView;
@property (weak, nonatomic) IBOutlet UIImageView *upArrow;
@property (weak, nonatomic) IBOutlet UIImageView *downArrow;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *lblCongrats;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UIButton *buttonContinue;
@property (weak, nonatomic) CircuitDocument *document;
@end

@implementation ProblemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _congratsView.alpha = 0.0;
    _congratsView.hidden = YES;
    self.isMinimised = NO;
    self.document = _document;
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
    _titleLabel.text = [NSString stringWithFormat:@"Problem #%lu - %@", (unsigned long)(_document.problemInfo.problemIndex + 1), _document.circuit.title];
    _bodyLabel.text = _document.circuit.userDescription;
}
- (void) showProgressToNextLevelScreen {
    _congratsView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        _congratsView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}
- (void) showWonGameScreen {
    _congratsView.hidden = NO;
    [self.buttonContinue setTitle:@"Go back to menu" forState:UIControlStateNormal];
    self.lblCongrats.text = @"Congratulations, you solved all the levels!";
    [UIView animateWithDuration:0.3 animations:^{
        _congratsView.alpha = 1;
    }];
}
- (IBAction)didTapProblemDescriptionToHide:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.delegate problemInfoViewController:self requestToggleVisibility:sender];
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate problemInfoViewController:self willToggleVisibility:sender];
    }
}

- (void) setIsMinimised:(BOOL)isMinimised {
    _isMinimised = isMinimised;
    _upArrow.alpha = _isMinimised ? 1.0 : 0.0;
    _downArrow.alpha = _isMinimised ? 0.0 : 1.0;
}

- (void) showProblemDescription {
    _congratsView.hidden = YES;
}

- (IBAction)continueButton:(id)sender {
    [self.delegate problemInfoViewController:self didPressContinueButton:sender];
}
@end
