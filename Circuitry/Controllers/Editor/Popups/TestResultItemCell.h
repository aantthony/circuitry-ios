//
//  TestResultItemCell.h
//  Circuitry
//
//  Created by Anthony Foster on 18/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

@class CircuitTestResult;
@class CircuitTestResultCheck;
@interface TestResultItemCell : UITableViewCell
@property (nonatomic) CircuitTestResultCheck *check;
@property (nonatomic) CircuitTestResult *result;
- (void) setShowResult:(BOOL) showResult animated:(BOOL) animated;
@end
