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
// TODO: remove this
#import <AssetsLibrary/AssetsLibrary.h>
#import "CircuitDocument.h"

@interface CircuitDocumentViewController () <CircuitObjectListTableViewControllerDelegate, ProblemInfoViewControllerDelegate, ViewControllerTutorialProtocol>
@property (nonatomic, weak) CircuitObjectListTableViewController *objectListViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *objectListLeft;
@property (nonatomic, weak) ProblemInfoViewController *problemInfoViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *problemInfoHeight;
@property (nonatomic, weak) ViewController *glkViewController;
@property (nonatomic) BOOL objectListVisible;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkAnswerButton;
@property (nonatomic) BOOL problemInfoVisible;
@property (nonatomic) UIImageView *hintViewTapAndHoldLeft;
@property (nonatomic) UIImageView *hintViewDragHereRight;
@property (nonatomic) UIImageView *hintViewCheckCorrect;
@property (nonatomic) NSInteger tutorialState;
@property (nonatomic) BOOL isTutorial;
@property (nonatomic) CircuitTestResult *testResult;
@property (nonatomic) CircuitDocument *nextDocument;
@end

@implementation CircuitDocumentViewController

- (BOOL) prefersStatusBarHidden {
    return NO;
}

- (void) setDocument:(CircuitDocument *) document {
    _objectListViewController.document = document;
    _glkViewController.document = document;
    _document = document;
    self.title = document.circuit.title;
    
    self.isTutorial = YES;
    
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
}

static CGPoint hvrTapAndHoldLeft = {225, 611};
static CGPoint hvrDragHereRight = {88,428};

- (UIImageView *) hintViewTapAndHoldLeft {
    if (_hintViewTapAndHoldLeft) return _hintViewTapAndHoldLeft;
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TapAndHoldOutlet"]];
    view.frame = CGRectMake(hvrTapAndHoldLeft.x, hvrTapAndHoldLeft.y, view.frame.size.width, view.frame.size.height);
    _hintViewTapAndHoldLeft = view;
    [self.view addSubview:view];
    return view;
}

- (UIImageView *) hintViewDragHereRight {
    if (_hintViewDragHereRight) return _hintViewDragHereRight;
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DragIntoHere"]];
    view.frame = CGRectMake(hvrDragHereRight.x, hvrDragHereRight.y, view.frame.size.width, view.frame.size.height);
    _hintViewDragHereRight = view;
    [self.view addSubview:view];
    return view;
}

- (UIImageView *) hintViewCheckCorrect {
    if (_hintViewCheckCorrect) return _hintViewCheckCorrect;
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckCorrect"]];
    view.frame = CGRectMake(350,100, view.frame.size.width, view.frame.size.height);
    _hintViewCheckCorrect = view;
    [self.view addSubview:view];
    return view;
}

- (void) updateTutorialState {
    
    CircuitObject *A = [self.document.circuit findObjectById:@"53c3cdc945f5603003000000"];
    CircuitObject *B = [self.document.circuit findObjectById:@"53c3cdc945f5603003000888"];
    
    if (!A || !B) {
        // TODO: No need to check here, we are not in the tutorial!
        return;
    }
    
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
    NSLog(@"tutorialState: %d", tutorialState);
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
        CGRect targetFrame = CGRectMake(hvrTapAndHoldLeft.x, hvrTapAndHoldLeft.y - 400, tapHold.frame.size.width, tapHold.frame.size.height);
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
        CGRect targetFrame = CGRectMake(hvrDragHereRight.x, hvrDragHereRight.y - 40, dragHere.frame.size.width, dragHere.frame.size.height);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self configureView];
}

- (void) configureView {
    self.objectListVisible = [self shouldShowToolbeltForDocument:_document];
    BOOL hasTests = _document.circuit.tests.count > 0;
    self.problemInfoVisible = hasTests;
    if (hasTests) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Check Answer" style:UIBarButtonItemStyleDone target:self action:@selector(checkAnswer:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Configure" style:UIBarButtonItemStyleDone target:self action:@selector(configureDocument:)];
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
    _problemInfoHeight.constant = problemInfoVisible ? 258 : 0;
}

- (IBAction)configureDocument:(id)sender {
    
}

- (BOOL) shouldShowToolbeltForDocument: (CircuitDocument *) doc {
    id toolbeltFlag = doc.circuit.meta[@"toolbelt"];
    if (toolbeltFlag == nil) return YES;
    return [toolbeltFlag boolValue];
}
- (IBAction)checkAnswer:(id)sender {
    if (_document.circuit.tests.count) {
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
//            [[[UIAlertView alloc] initWithTitle:@"Test Result" message: failure.resultDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        } else {
            [[AnalyticsManager shared] trackFinishProblem:self.document];
            if (self.isTutorial) {
                [self finishTutorial];
            }
            
            CircuitDocument *doc = [self.delegate circuitDocumentViewController:self nextDocumentAfterDocument:self.document];
            self.nextDocument = doc;
            [doc openWithCompletionHandler:nil];
            
            if (self.nextDocument) {
                [_problemInfoViewController showProgressToNextLevelScreen];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
            // Success!
        }
    }
}


#pragma mark - Toolbelt delegate

- (void) tableViewController:(CircuitObjectListTableViewController *)tableViewController didStartCreatingObject:(ToolbeltItem *)item {
    [_glkViewController startCreatingObjectFromItem: item];
}


- (UIImage *) screenshotForView:(UIView *)view {
    UIImage *img;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        img = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - Problem Info delegate
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id)sender {
    UIImage *screenShotView = [self screenshotForView:self.view];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:screenShotView];
    
    [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[screenShotView CGImage] orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
        NSLog(@"finished %@, %@", assetURL, error);
    }];
    
    imgView.image = nil;
    imgView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:imgView];
    
    [_problemInfoViewController showProblemDescription];
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
