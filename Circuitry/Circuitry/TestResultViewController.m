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
@property (nonatomic) BOOL hasAppeared;
@end

@implementation TestResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configure];
}

- (void) setTestResult:(CircuitTestResult *)testResult {
    _testResult = testResult;
    [self.tableView reloadData];
}


typedef void (^Function)();


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __block NSMutableArray *cellsToAnimate = [NSMutableArray array];
    for(NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (!cell) continue;
        if (cell.tag == 500) continue;
        TestResultItemCell *itemCell = (TestResultItemCell *)cell;
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
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

@end
