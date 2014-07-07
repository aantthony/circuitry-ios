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

@interface CircuitDocumentViewController ()
@property (nonatomic) CircuitDocument *document;
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

- (void) setDocument:(CircuitDocument *) document {
    NSLog(@"CONTROLLERS: %@",  self.childViewControllers);
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[CircuitObjectListTableViewController class]]) {
        CircuitObjectListTableViewController *controller = (CircuitObjectListTableViewController *) segue.destinationViewController;
        controller.document = self.document;
    } else if ([segue.destinationViewController isKindOfClass:[ViewController class]]) {
        ViewController *controller = (ViewController *) segue.destinationViewController;
        controller.document = self.document;
    }
}

@end
