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

@interface CircuitDocumentViewController () <CircuitObjectListTableViewControllerDelegate>
@property (nonatomic) CircuitDocument *document;
@property (nonatomic, weak) CircuitObjectListTableViewController *objectListViewController;
@property (nonatomic, weak) ViewController *glkViewController;

@end

@implementation CircuitDocumentViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
}

#pragma mark - Toolbelt delegate

- (void) tableViewController:(CircuitObjectListTableViewController *)tableViewController didStartCreatingObject:(ToolbeltItem *)item {
    [_glkViewController startCreatingObjectFromItem: item];
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
    }
}

@end
