//
//  TestResultViewController.m
//  Circuitry
//
//  Created by Anthony Foster on 18/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import "TestResultViewController.h"
#import "TestResultItemCell.h"
#import "CircuitTestResult.h"

@interface TestResultViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *bigTick;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIView *buttonSeparator;
@property (nonatomic) BOOL hasAppeared;
@end

@implementation TestResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configure];
    _bigTick.hidden = YES;
    [self updatePreferredContentSize];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    static const CGFloat buttonHeight = 74.0;
    static const CGFloat separatorHeight = 1.0;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat tableHeight = MAX(0.0, CGRectGetHeight(self.view.bounds) - buttonHeight);

    self.tableView.frame = CGRectMake(0.0, 0.0, width, tableHeight);
    self.buttonSeparator.frame = CGRectMake(0.0, tableHeight, width, separatorHeight);
    self.dismissButton.frame = CGRectMake(0.0, tableHeight, width, buttonHeight);
}

- (void)updatePreferredContentSize {
    static const CGFloat sheetWidth = 540.0;
    static const CGFloat rowHeight = 50.0;
    static const CGFloat buttonHeight = 74.0;
    static const CGFloat maximumSheetHeight = 620.0;

    NSUInteger checkCount = self.testResult.checks.count;
    CGFloat tableHeight = rowHeight * (checkCount + 1); // Result rows plus header.
    CGFloat sheetHeight = MIN(maximumSheetHeight, tableHeight + buttonHeight);
    self.preferredContentSize = CGSizeMake(sheetWidth, sheetHeight);
}

- (void) setTestResult:(CircuitTestResult *)testResult {
    _testResult = testResult;
    [self.tableView reloadData];
    [self updatePreferredContentSize];
}


//typedef void (^Function)();

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __block NSMutableArray *cellsToAnimate = [NSMutableArray array];
    for(NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (!cell) continue;
        if (cell.tag == 500) continue;
//        TestResultItemCell *itemCell = (TestResultItemCell *)cell;
        [cellsToAnimate addObject:cell];
    }
    
    CGFloat delayStart = 0;
    for (TestResultItemCell *cell in cellsToAnimate) {
        delayStart += 0.05;
        [UIView animateWithDuration:0.2 delay:delayStart options:UIViewAnimationOptionCurveEaseOut animations:^{
            [cell setShowResult:YES animated:NO];
        } completion:nil];
    }
    self.hasAppeared = YES;
    if (self.testResult.passed) {
        
        self.bigTick.hidden = NO;
        self.bigTick.alpha = 0.0;
        self.bigTick.transform = CGAffineTransformMakeScale(5.0, 5.0);
        
        [UIView animateWithDuration:0.35 delay:delayStart + 0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.bigTick.alpha = 1.0;
            self.bigTick.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.2 animations:^{
                self.bigTick.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(0.4), CGAffineTransformMakeScale(1.2, 1.2));
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.bigTick.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(-0.4), CGAffineTransformMakeScale(1.2, 1.2));
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2 animations:^{
                        self.bigTick.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.8 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            self.bigTick.alpha = 0.0;
                        } completion:nil];
                    }];
                }];
            }];

            
        }];
        
    }
}

- (void) configure {
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return _testResult.checks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        TestResultItemCell * cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
        cell.result = _testResult;
        cell.tag = 500;
        return cell;
    }
    TestResultItemCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    CircuitTestResultCheck *check = _testResult.checks[indexPath.row];
    cell.check = check;
    if (!self.hasAppeared) {
        [cell setShowResult:NO animated:NO];
    } else {
        [cell setShowResult:YES animated:NO];
    }
    return cell;
}
-
(IBAction)dismiss:(id)sender {
    [self.delegate testResultViewController:self didFinish:sender];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

@end
