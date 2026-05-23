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
@property (nonatomic) UIButton *hintButton;
@property (nonatomic) NSUInteger visibleHintCount;
@end

@implementation ProblemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _congratsView.alpha = 0.0;
    _congratsView.hidden = YES;
    [self createHintButton];
    self.isMinimised = NO;
    self.document = _document;
}

- (void)createHintButton {
    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.size.width = self.view.bounds.size.width - 155;
    self.titleLabel.frame = titleFrame;

    UIButton *hintButton = [UIButton buttonWithType:UIButtonTypeSystem];
    hintButton.frame = CGRectMake(self.view.bounds.size.width - 124, 12, 74, 32);
    hintButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    hintButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [hintButton setTitle:@"Hint" forState:UIControlStateNormal];
    [hintButton addTarget:self action:@selector(showNextHint:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hintButton];
    self.hintButton = hintButton;
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
    _visibleHintCount = 0;
    _titleLabel.text = [NSString stringWithFormat:@"Problem #%lu - %@", (unsigned long)(_document.problemInfo.problemIndex + 1), _document.circuit.title];
    _bodyLabel.text = _document.circuit.userDescription;
    [self updateHintButton];
}
- (void) showProgressToNextLevelScreen {
    _congratsView.hidden = NO;
    self.hintButton.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
        _congratsView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}
- (void) showWonGameScreen {
    _congratsView.hidden = NO;
    self.hintButton.hidden = YES;
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
    [self updateHintButton];
}

- (IBAction)continueButton:(id)sender {
    [self.delegate problemInfoViewController:self didPressContinueButton:sender];
}

- (void)updateHintButton {
    NSArray *hints = _document.circuit.hints;
    self.hintButton.hidden = _congratsView.hidden == NO || hints.count == 0;
    NSString *title = _visibleHintCount > 0 ? [NSString stringWithFormat:@"Hint %lu/%lu", (unsigned long)_visibleHintCount, (unsigned long)hints.count] : @"Hint";
    [self.hintButton setTitle:title forState:UIControlStateNormal];
}

- (IBAction)showNextHint:(id)sender {
    NSArray *hints = _document.circuit.hints;
    if (hints.count == 0) return;

    if (_visibleHintCount < hints.count) {
        _visibleHintCount++;
    }

    NSMutableString *message = [NSMutableString string];
    for (NSUInteger i = 0; i < _visibleHintCount; i++) {
        if (i > 0) [message appendString:@"\n\n"];
        [message appendFormat:@"%lu. %@", (unsigned long)(i + 1), hints[i]];
    }

    [self updateHintButton];

    [[[UIAlertView alloc] initWithTitle:@"Hint" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
@end
