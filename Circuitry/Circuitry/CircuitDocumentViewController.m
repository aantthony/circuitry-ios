//
//  CircuitDocumentViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 6/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitDocumentViewController.h"

#import "CircuitObjectListTableViewController.h"
#import "ViewController.h"
#import "ProblemInfoViewController.h"
#import "AnalyticsManager.h"
#import "TestResultViewController.h"
#import "CircuitTest.h"
#import "Viewport.h"
#import "CircuitDocument.h"
#import "ProblemSetProblemInfo.h"

@interface CircuitDocumentViewController () <CircuitObjectListTableViewControllerDelegate, ProblemInfoViewControllerDelegate, ViewControllerTutorialProtocol, UITextFieldDelegate>
@property (nonatomic, weak) CircuitObjectListTableViewController *objectListViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *objectListLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *problemInfoBottom;
@property (nonatomic, weak) ProblemInfoViewController *problemInfoViewController;
@property (nonatomic, weak) ViewController *glkViewController;
@property (nonatomic) BOOL objectListVisible;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkAnswerButton;
@property (nonatomic) BOOL problemInfoVisible;
@property (nonatomic) BOOL problemInfoMinimised;
@property (nonatomic) UIImageView *hintViewTapAndHoldLeft;
@property (nonatomic) UIImageView *hintViewDragHereRight;
@property (nonatomic) UIImageView *hintViewCheckCorrect;
@property (nonatomic) NSInteger tutorialState;
@property (nonatomic) UIView *titleView;
@property (nonatomic) BOOL isTutorial;
@property (nonatomic) CircuitTestResult *testResult;
@property (nonatomic) CircuitDocument *nextDocument;
@property (nonatomic) UITapGestureRecognizer *tapToDismissKeyboard;
@property (nonatomic) BOOL hasShownIntroText;
@end

@implementation CircuitDocumentViewController

- (BOOL) prefersStatusBarHidden {
    return NO;
}

- (UIImage *) snapshot {
    return _glkViewController.snapshot;
}

- (UIView *) titleView {
    if (!_titleView) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTitleView:)];
        [label addGestureRecognizer:tap];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = YES;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
        _titleView = label;
    }
    
    UILabel *label = (UILabel *)_titleView;
    
    label.textColor = self.view.tintColor;
    
    label.text = self.document.circuit.title;
    if (!label.text.length) {
        label.text = @"Untitled";
    }
    
    return _titleView;
}

- (UITapGestureRecognizer* ) tapToDismissKeyboard {
    if (!_tapToDismissKeyboard) {
        _tapToDismissKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    }
    
    return _tapToDismissKeyboard;
}

- (void) dismissKeyboard:(id)sender {
    UIView *titleView = self.navigationItem.titleView;
    if (![titleView isKindOfClass:[UITextField class]]) {
        return;
    }
    UITextField *field = (UITextField *)titleView;
    [field resignFirstResponder];
    [self textFieldShouldReturn:field];
}

- (void) didTapTitleView:(id) sender {
    if (!self.document) return;
    if (self.document.isProblem) return;
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
    field.textAlignment = NSTextAlignmentCenter;
    field.text = self.document.circuit.title;
    NSRange r = [field.text rangeOfString:@"Blank "];
    if (r.location != NSNotFound) {
        field.text = @"";
    }
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.delegate = self;
    field.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
    field.returnKeyType = UIReturnKeyDone;
    self.navigationItem.titleView = field;
    [self.view addGestureRecognizer:self.tapToDismissKeyboard];
    self.glkViewController.view.userInteractionEnabled = NO;
    [self.navigationController.navigationBar layoutSubviews];
    
    [field becomeFirstResponder];
}

- (void) configureTitleView {
    self.navigationItem.titleView = self.titleView;
    [self.navigationController.navigationBar layoutIfNeeded];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length) {
        _document.circuit.title = textField.text;
    }
    [_document updateChangeCount:UIDocumentChangeDone];
    [self configureTitleView];
    
    [self.view removeGestureRecognizer:_tapToDismissKeyboard];
    self.tapToDismissKeyboard = nil;
    self.glkViewController.view.userInteractionEnabled = YES;

    return YES;
}

- (void) setDocument:(CircuitDocument *) document {
    NSParameterAssert(document.circuit);
    
    _objectListViewController.document = document;
    _glkViewController.document = document;
    _problemInfoViewController.document = document;
    
    _document = document;
    self.title = document.circuit.title;
    
    self.isTutorial = document.problemInfo.problemIndex == 0;
    
    [self configureTitleView];
    
    [[AnalyticsManager shared] trackStartProblem:document];
    if (self.view) {
        [self configureView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _objectListViewController.document = _document;
    _glkViewController.document = _document;
    [self configureView];
    [self configureTitleView];
}

static CGPoint hvrTapAndHoldLeft = {225, 611};
static CGPoint hvrDragHereRight = {88,428};

- (BOOL) landscape {
    return self.view.frame.size.width > self.view.frame.size.height;
}

- (UIImageView *) hintViewTapAndHoldLeft {
    if (!_hintViewTapAndHoldLeft) {
        _hintViewTapAndHoldLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TapAndHoldOutlet"]];
        [self.view addSubview:_hintViewTapAndHoldLeft];
    }
    
    if (self.landscape) {
        hvrTapAndHoldLeft.y = 411;
    } else {
        hvrTapAndHoldLeft.y = 611;
    }
    
    _hintViewTapAndHoldLeft.frame = CGRectMake(
                                               hvrTapAndHoldLeft.x,
                                               hvrTapAndHoldLeft.y,
                                               _hintViewTapAndHoldLeft.frame.size.width,
                                               _hintViewTapAndHoldLeft.frame.size.height
                                               );
    return _hintViewTapAndHoldLeft;
}

- (UIImageView *) hintViewDragHereRight {
    if (!_hintViewDragHereRight) {
        _hintViewDragHereRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DragIntoHere"]];
        [self.view addSubview:_hintViewDragHereRight];
    }
    if (self.landscape) {
        hvrDragHereRight.y = 326;
        hvrDragHereRight.x = 200;
    } else {
        hvrDragHereRight.y = 428;
        hvrDragHereRight.x = 88;
    }
    _hintViewDragHereRight.frame = CGRectMake(
                                              hvrDragHereRight.x,
                                              hvrDragHereRight.y,
                                              _hintViewDragHereRight.frame.size.width,
                                              _hintViewDragHereRight.frame.size.height
                                              );
    return _hintViewDragHereRight;
}

- (UIImageView *) hintViewCheckCorrect {
    if (!_hintViewCheckCorrect) {
        _hintViewCheckCorrect = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckCorrect"]];
        [self.view addSubview:_hintViewCheckCorrect];
    }
    
    CGRect rect = CGRectMake(
                                             320,
                                             80,
                                             _hintViewCheckCorrect.frame.size.width,
                                             _hintViewCheckCorrect.frame.size.height
                                             );
    
    if (self.landscape) {
        rect.origin.x = 570;
    }
    _hintViewCheckCorrect.frame = rect;
    return _hintViewCheckCorrect;
}

- (void) ensureObjectIsAtPosition:(CircuitObject *)object x:(float)x y:(float)y {
    float dx = object->pos.x - x;
    float dy = object->pos.y - y;
    float d2 = dx * dx + dy * dy;
    if (d2 == 0.0) {
        return;
    }
    
    object->pos.y = x;
    object->pos.y = y;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortrait)
        return YES;
    
    return NO;
}

- (void) updateTutorialState {
    
    CircuitObject *A = [self.document.circuit findObjectById:@"53c3cdc945f5603003000000"];
    CircuitObject *B = [self.document.circuit findObjectById:@"53c3cdc945f5603003000888"];
    
    if (!A || !B) {
        // TODO: No need to check here, we are not in the tutorial!
        return;
    }
    
//    [self ensureObjectIsAtPosition:A x:0 y:0];
    
    if (B->outputs[0]) {
        if (A->outputs[0]) {
            self.tutorialState = 6;
            return;
        }
        if (_glkViewController.viewport.currentEditingLinkSource == A && _glkViewController.viewport.currentEditingLinkSourceIndex == 0) {
            self.tutorialState = 5;
            return;
        }
        if (_glkViewController.viewport.currentEditingLinkSource == B && _glkViewController.viewport.currentEditingLinkSourceIndex == 0) {
            self.tutorialState = 3;
            return;
        }
        self.tutorialState = 4;
    } else {
        
        if (_glkViewController.viewport.currentEditingLinkSource == B && _glkViewController.viewport.currentEditingLinkSourceIndex == 0) {
            self.tutorialState = 2;
            return;
        }
        self.tutorialState = 1;
        return;
    }
}

- (void) viewControllerTutorial:(ViewController *)viewController didChange:(id)sender {
    if (!self.isTutorial) return;
    [self updateTutorialState];
}

- (void) finishTutorial {
    self.isTutorial = NO;
    self.tutorialState = 0;
}

- (void) setTutorialState:(NSInteger)tutorialState {
    if (_tutorialState == tutorialState) return;
    _tutorialState = tutorialState;
    if (tutorialState == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            _hintViewTapAndHoldLeft.alpha = 0;
            _hintViewDragHereRight.alpha = 0;
            _hintViewCheckCorrect.alpha = 0;
        }];
    } else if (tutorialState == 1) {
        UIView *tapHold = self.hintViewTapAndHoldLeft;
        tapHold.alpha = 0;
        CGRect targetFrame = CGRectMake(hvrTapAndHoldLeft.x, hvrTapAndHoldLeft.y, tapHold.frame.size.width, tapHold.frame.size.height);
        targetFrame.origin.x += 150;
        tapHold.frame = targetFrame;
        targetFrame.origin.x -= 150;
        [UIView animateWithDuration:0.5 animations:^{
            tapHold.alpha = 1;
            tapHold.frame = targetFrame;
            _hintViewDragHereRight.alpha = 0;
            _hintViewCheckCorrect.alpha = 0;
        }];
    } else if (tutorialState == 2) {
        UIView *dragHere = self.hintViewDragHereRight;
        CGRect targetFrame = CGRectMake(hvrDragHereRight.x, hvrDragHereRight.y, dragHere.frame.size.width, dragHere.frame.size.height);
        targetFrame.origin.x -= 20;
        dragHere.frame = targetFrame;
        targetFrame.origin.x += 20;
        dragHere.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            dragHere.alpha = 1;
            _hintViewTapAndHoldLeft.alpha = 0;
            _hintViewCheckCorrect.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    } else if (tutorialState == 4) {
        UIView *tapHold = self.hintViewTapAndHoldLeft;
        tapHold.alpha = 0;
        CGFloat offsetY = self.landscape ? 200 : 400;
        CGRect targetFrame = CGRectMake(hvrTapAndHoldLeft.x, hvrTapAndHoldLeft.y - offsetY, tapHold.frame.size.width, tapHold.frame.size.height);
        targetFrame.origin.x += 150;
        tapHold.frame = targetFrame;
        targetFrame.origin.x -= 150;
        [UIView animateWithDuration:0.5 animations:^{
            tapHold.alpha = 1;
            tapHold.frame = targetFrame;
            _hintViewDragHereRight.alpha = 0;
        }];
    } else if (tutorialState == 5) {
        UIView *dragHere = self.hintViewDragHereRight;
        CGFloat offsetY = self.landscape ? 20 : 40;
        CGRect targetFrame = CGRectMake(hvrDragHereRight.x, hvrDragHereRight.y - offsetY, dragHere.frame.size.width, dragHere.frame.size.height);
        targetFrame.origin.x -= 20;
        dragHere.frame = targetFrame;
        targetFrame.origin.x += 20;
        dragHere.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            dragHere.alpha = 1;
            _hintViewTapAndHoldLeft.alpha = 0;
            _hintViewCheckCorrect.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    } else if (tutorialState == 6) {
        UIView *arrow = self.hintViewCheckCorrect;
        arrow.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            _hintViewTapAndHoldLeft.alpha = 0;
            _hintViewDragHereRight.alpha = 0;
        }];
        [UIView animateWithDuration:1.0 animations:^{
            arrow.alpha = 1;
        }];
    }
    
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSInteger tutorialState = _tutorialState;
    if (tutorialState == 0) return;
    [UIView animateWithDuration:0.01 animations:^{
        _hintViewTapAndHoldLeft.alpha = 0;
        _hintViewDragHereRight.alpha = 0;
        _hintViewCheckCorrect.alpha = 0;
    }];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _tutorialState = 0;
            self.tutorialState = tutorialState;
        });
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configureView];
    if (self.isTutorial) {
        if (!_hasShownIntroText) {
            [self performSegueWithIdentifier:@"ShowIntroText" sender:self];
            _hasShownIntroText = YES;
        }
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.delegate circuitDocumentViewController:self didFinish:self.document];
}

- (void) configureView {
    self.objectListVisible = [self shouldShowToolbeltForDocument:_document];
    BOOL hasTests = _document.circuit.tests.count > 0;
    self.problemInfoVisible = hasTests;
    if (hasTests) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Check Answer" style:UIBarButtonItemStyleDone target:self action:@selector(checkAnswer:)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) setObjectListVisible:(BOOL)objectListVisible {
    [self setObjectListVisible:objectListVisible animate:NO];
}

- (void) setObjectListVisible:(BOOL)objectListVisible animate:(BOOL)animate {
    _objectListVisible = objectListVisible;
    if (!animate) {
        _objectListView.hidden = !_objectListVisible;
        _objectListLeft.constant = _objectListVisible ? 0 : -_objectListView.frame.size.width;
        [self.view layoutIfNeeded];
        return;
    }
    
    _objectListView.hidden = NO;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.2 animations:^{
        _objectListLeft.constant = _objectListVisible ? 0 : -_objectListView.frame.size.width;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        _objectListView.hidden = !_objectListVisible;
    }];
}

- (void) setProblemInfoVisible:(BOOL) problemInfoVisible {
    _problemInfoVisible = problemInfoVisible;
    _problemInfoView.hidden = !problemInfoVisible;
    _problemInfoBottom.constant = problemInfoVisible ? 0 : -258;
    [self.view layoutIfNeeded];
}

- (void) setProblemInfoMinimised:(BOOL)problemInfoMinimised {
    _problemInfoMinimised = problemInfoMinimised;
    _problemInfoBottom.constant = _problemInfoMinimised ? -200 : 0;
    _problemInfoViewController.isMinimised = _problemInfoMinimised;
    [self.view layoutIfNeeded];
}

- (void) setProblemInfoMinimised:(BOOL)problemInfoMinimised animated:(BOOL) animated {
    if (!animated) {
        [self setProblemInfoMinimised:problemInfoMinimised];
        return;
    }
    _problemInfoMinimised = problemInfoMinimised;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.problemInfoMinimised = _problemInfoMinimised;
    } completion:nil];
}

- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController requestToggleVisibility:(id)sender {
    
    BOOL shouldMinimise = !_problemInfoMinimised;
    [self setProblemInfoMinimised:shouldMinimise animated:YES];
}

- (BOOL) shouldShowToolbeltForDocument: (CircuitDocument *) doc {
    id toolbeltFlag = doc.circuit.meta[@"toolbelt"];
    if (toolbeltFlag == nil) return YES;
    if ([toolbeltFlag isKindOfClass:[NSArray class]]) {
        return YES;
    }
    return [toolbeltFlag boolValue];
}
- (IBAction)checkAnswer:(UIBarButtonItem *)sender {
    if (!_document.circuit.tests.count) {
        [[[UIAlertView alloc] initWithTitle:@"No Test" message:@"Unspecified." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    __block CircuitTestResult *failure = nil;
    [_document.circuit.tests enumerateObjectsUsingBlock:^(CircuitTest *test, NSUInteger idx, BOOL *stop) {
        CircuitTestResult *testResult = [test runAndSimulate:_document.circuit];
        if (!testResult.passed) {
            failure = testResult;
            *stop = YES;
        }
    }];
    
    if (failure) {
        [[AnalyticsManager shared] trackCheckProblem:self.document withResult:failure];
        self.testResult = failure;
        [self performSegueWithIdentifier:@"ShowTestResult" sender:self];
        
    } else {
        [[AnalyticsManager shared] trackFinishProblem:self.document];
        if (self.isTutorial) {
            [self finishTutorial];
        }
        
        CircuitDocument *doc = [self.delegate circuitDocumentViewController:self nextDocumentAfterDocument:self.document];
        self.nextDocument = doc;
        
        sender.enabled = NO;
        
        if (self.nextDocument) {
            [_problemInfoViewController showProgressToNextLevelScreen];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        // Success!
    }
}


#pragma mark - Toolbelt delegate

- (void) tableViewController:(CircuitObjectListTableViewController *)tableViewController didStartCreatingObject:(ToolbeltItem *)item {
    [_glkViewController startCreatingObjectFromItem: item];
}


#pragma mark - Problem Info delegate
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id)sender {
    
    UIView *imgView = [[UIView alloc] init];
    imgView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:imgView];
    
    [_problemInfoViewController showProblemDescription];
    
    // TODO: Ensure this
    NSParameterAssert(self.nextDocument.circuit);
    if (!self.nextDocument.circuit) {
        return;
    }
    self.document = self.nextDocument;
    
    [UIView animateWithDuration:0.5 animations:^{
        imgView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [imgView removeFromSuperview];
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *d = segue.destinationViewController;
    if ([d isKindOfClass:[CircuitObjectListTableViewController class]]) {
        CircuitObjectListTableViewController *controller = (CircuitObjectListTableViewController *) d;
        _objectListViewController = controller;
        controller.delegate = self;
        controller.document = self.document;
    } else if ([d isKindOfClass:[ViewController class]]) {
        ViewController *controller = (ViewController *) d;
        _glkViewController = controller;
        _glkViewController.tutorialDelegate = self;
        controller.document = self.document;
    } else if ([d isKindOfClass:ProblemInfoViewController.class]) {
        ProblemInfoViewController * controller = (ProblemInfoViewController *) d;
        _problemInfoViewController = controller;
        controller.delegate = self;
        controller.document = self.document;
    } else if ([d isKindOfClass:[TestResultViewController class]]) {
        TestResultViewController *vc = (TestResultViewController *)d;
        vc.testResult = self.testResult;
    }
}

@end
