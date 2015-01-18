//
//  CircuitTestResult.h
//  Circuitry
//
//  Created by Anthony Foster on 20/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CircuitTestResultCheck : NSObject
@property (nonatomic, readonly) NSArray *inputs;
@property (nonatomic, readonly) NSArray *expectedOutputs;
@property (nonatomic, readonly) BOOL isMatch;
- (instancetype) initWithInputs:(NSArray *)inputs expectedOutputs:(NSArray *)expectedOutputs match:(BOOL)match;
@end

@interface CircuitTestResult : NSObject
@property (nonatomic, readonly) NSString *resultDescription;
@property (nonatomic, readonly) BOOL passed;
@property (nonatomic, readonly) NSArray *checks;
@property (nonatomic, readonly) NSArray *inputNames;
- (instancetype) initWithResultDescription:(NSString *)resultDesription passed:(BOOL)passed checks:(NSArray *)checks inputNames:(NSArray *)inputNames;
@end
