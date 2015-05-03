//
//  CircuitTest.h
//  Circuitry
//
//  Created by Anthony Foster on 20/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitTestResult.h"

@interface CircuitTest : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *spec;

- (CircuitTestResult *) runAndSimulate:(id)circuit;

- (id) initWithName: (NSString *)name inputs:(NSArray *) inputs outputs: (NSArray *)outputs spec: (NSArray *) spec;
- (NSArray *) inputIds;
- (NSArray *) outputIds;
@end
