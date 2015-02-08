//
//  CircuitTestResult.m
//  Circuitry
//
//  Created by Anthony Foster on 20/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitTestResult.h"

@implementation CircuitTestResultCheck
- (instancetype) initWithInputs:(NSArray *)inputs expectedOutputs:(NSArray *)expectedOutputs match:(BOOL)match {
    self = [super init];
    _inputs = [inputs copy];
    _expectedOutputs = [expectedOutputs copy];
    _isMatch = match;
    return self;
}
@end


@implementation CircuitTestResult
- (instancetype) initWithResultDescription:(NSString *)resultDesription passed:(BOOL)passed checks:(NSArray *)checks inputNames:(NSArray *)inputNames outputNames:(NSArray *)outputNames {
    self = [super init];
    _resultDescription = [resultDesription copy];
    _passed = passed;
    _checks = [checks copy];
    _inputNames = [inputNames copy];
    _outputNames = [outputNames copy];
    return self;
}
@end
