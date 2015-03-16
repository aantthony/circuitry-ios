//
//  TestResultViewController.h
//  Circuitry
//
//  Created by Anthony Foster on 18/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

@class CircuitTestResult;
@protocol TestResultViewControllerDelegate;
@interface TestResultViewController : UIViewController
@property (nonatomic) CircuitTestResult *testResult;
@property (nonatomic, weak) id<TestResultViewControllerDelegate> delegate;
@end

@protocol TestResultViewControllerDelegate <NSObject>

@required
- (void) testResultViewController:(TestResultViewController *)viewController didFinish:(id) sender;

@end