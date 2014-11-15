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

@interface CircuitDocumentViewController () <CircuitObjectListTableViewControllerDelegate, ProblemInfoViewControllerDelegate>
@property (nonatomic) CircuitDocument *document;
@property (nonatomic, weak) CircuitObjectListTableViewController *objectListViewController;
@property (nonatomic, weak) ProblemInfoViewController *problemInfoViewController;
@property (nonatomic, weak) ViewController *glkViewController;
@property (nonatomic) BOOL objectListVisible;
@property (nonatomic) BOOL problemInfoVisible;
@end

@implementation CircuitDocumentViewController

- (BOOL) prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
//    return UIStatusBarStyleLightContent;
}


- (void) setDocument:(CircuitDocument *) document {
    _objectListViewController.document = document;
    _glkViewController.document = document;
    _document = document;
    [self configureView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
//    self.navigationController.navigationBarHidden = YES;
    [super viewDidAppear:animated];
    [self configureView];
}

- (void) configureView {
    self.objectListVisible = [self shouldShowToolbeltForDocument:_document];
    BOOL hasTests = _document.circuit.tests.count > 0;
    self.problemInfoVisible = hasTests;
}

- (void) setObjectListVisible:(BOOL)objectListVisible {
    _objectListVisible = objectListVisible;
    _objectListView.hidden = !_objectListVisible;
}

- (void) setProblemInfoVisible:(BOOL) problemInfoVisible {
    _problemInfoVisible = problemInfoVisible;
    _problemInfoView.hidden = !problemInfoVisible;
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
            [[[UIAlertView alloc] initWithTitle:@"Test Result" message: failure.resultDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        } else {
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
