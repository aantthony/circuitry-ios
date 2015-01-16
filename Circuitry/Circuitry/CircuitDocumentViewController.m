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

@interface CircuitDocumentViewController () <CircuitObjectListTableViewControllerDelegate, ProblemInfoViewControllerDelegate>
@property (nonatomic) CircuitDocument *document;
@property (nonatomic, weak) CircuitObjectListTableViewController *objectListViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *objectListLeft;
@property (nonatomic, weak) ProblemInfoViewController *problemInfoViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *problemInfoHeight;
@property (nonatomic, weak) ViewController *glkViewController;
@property (nonatomic) BOOL objectListVisible;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkAnswerButton;
@property (nonatomic) BOOL problemInfoVisible;
@end

@implementation CircuitDocumentViewController

- (BOOL) prefersStatusBarHidden {
    return NO;
}

- (void) setDocument:(CircuitDocument *) document {
    _objectListViewController.document = document;
    _glkViewController.document = document;
    _document = document;
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
            [[[UIAlertView alloc] initWithTitle:@"Test Result" message: failure.resultDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        } else {
            [[AnalyticsManager shared] trackFinishProblem:self.document];
            // Success!
            [_problemInfoViewController showProgressToNextLevelScreen];
        }
    }
}


#pragma mark - Toolbelt delegate

- (void) tableViewController:(CircuitObjectListTableViewController *)tableViewController didStartCreatingObject:(ToolbeltItem *)item {
    [_glkViewController startCreatingObjectFromItem: item];
}

#pragma mark - Problem Info delegate
- (void) problemInfoViewController:(ProblemInfoViewController *)problemInfoViewController didPressContinueButton:(id)sender {
    NSLog(@"Completed problem: %@", self.document);
    NSLog(@"Finding next problem...");
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[CircuitObjectListTableViewController class]]) {
        CircuitObjectListTableViewController *controller = (CircuitObjectListTableViewController *) segue.destinationViewController;
        _objectListViewController = controller;
        controller.delegate = self;
        controller.document = self.document;
    } else if ([segue.destinationViewController isKindOfClass:[ViewController class]]) {
        ViewController *controller = (ViewController *) segue.destinationViewController;
        _glkViewController = controller;
        controller.document = self.document;
    } else if ([segue.destinationViewController isKindOfClass:ProblemInfoViewController.class]) {
        ProblemInfoViewController * controller = (ProblemInfoViewController *) segue.destinationViewController;
        _problemInfoViewController = controller;
        controller.delegate = self;
        controller.document = self.document;
    }
}

@end
