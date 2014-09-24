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
@property (weak, nonatomic) CircuitDocument *document;
@end

@implementation ProblemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setDocument: (CircuitDocument *) document {
    _document = document;
}

@end
