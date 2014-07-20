//
//  CircuitTest.m
//  Circuitry
//
//  Created by Anthony Foster on 20/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitTest.h"
#import "Circuit.h"

@interface CircuitTest()
@property (nonatomic) NSArray *inputNodes;
@property (nonatomic) NSArray *outputNodes;
@end
@implementation CircuitTest

- (id) initWithName: (NSString *)name inputs:(NSArray *) inputs outputs: (NSArray *)outputs spec: (NSArray *) spec {
    self = [super init];
    _name = name;
    _inputNodes = inputs;
    _outputNodes = outputs;
    _spec = spec;
    return self;
}

- (NSArray *) inputIds {
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:_inputNodes.count];
    [_inputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *circuitObject = [obj pointerValue];
        [ids addObject: [MongoID stringWithId:circuitObject->id]];
    }];
    return ids;
}

- (NSArray *) outputIds {
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:_outputNodes.count];
    [_outputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *circuitObject = [obj pointerValue];
        [ids addObject: [MongoID stringWithId:circuitObject->id]];
    }];
    return ids;
}

+ (NSString *) binaryString:(int) n length: (int) cap{
    NSString *s = @"";
    BOOL first = YES;
    int B = 1;
    for(int i = cap - 1; i >= 0; i--) {
        if (!first) {
            s = [s stringByAppendingString:@", "];
        }
        s = [s stringByAppendingFormat:@"%d", n & B ? 1 : 0];
        if (n & B) {
            s = [s stringByAppendingString:@"1"];
        } else {
            s = [s stringByAppendingString:@"0"];
        }
        B <<= 1;
        first = NO;
    }
    return s;
}

- (CircuitTestResult *) runAndSimulate:(Circuit *)circuit {
    __block BOOL pass = YES;
    
    // determine initial input state:
    NSMutableArray *initalStates = [NSMutableArray arrayWithCapacity:_inputNodes.count];
    
    [_inputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject * inputNode = [obj pointerValue];
        [initalStates addObject:@(inputNode->out)];
    }];
    
    __block NSString *failure = @"";

    [_spec enumerateObjectsUsingBlock:^(NSArray *inputOutputPair, NSUInteger idx, BOOL *stop) {
        NSArray *inputStates = inputOutputPair[0];
        NSArray *outputStates = inputOutputPair[1];
        
        // Apply input state:
        [inputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * inputNode = [_inputNodes[i] pointerValue];
            inputNode->out = [obj intValue];
            [circuit didUpdateObject:inputNode];
        }];

        [circuit simulate:512];
        
        // Validate output state:
        [outputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * outputNode = [_outputNodes[i] pointerValue];
            int expected = [obj intValue];
            if (outputNode->in != expected) {
                pass = NO;
                
                NSString *inputStateSpecification = [inputStates componentsJoinedByString:@", "];
                NSString *outputStateSpecification = [outputStates componentsJoinedByString:@", "];
                
                if (failure) {
                    failure = [failure stringByAppendingString:@"\n"];
                }
                failure = [failure stringByAppendingFormat:@"f(%@) == (%@) failed: expected %s to equal %d, but got %d instead.", inputStateSpecification, outputStateSpecification, outputNode->name, expected, outputNode->in];
                
                //*stop = YES;
            }
        }];
        
        //if (!pass) *stop = YES;

    }];
    
    // Re-apply inital input state:
    [initalStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
        CircuitObject * inputNode = [_inputNodes[i] pointerValue];
        inputNode->out = [obj intValue];
        [circuit didUpdateObject:inputNode];
    }];

    CircuitTestResult *result = [[CircuitTestResult alloc] init];
    result.passed = pass;
    
    if (pass) {
        result.resultDescription = [NSString stringWithFormat:@"Passed."];
    } else {
        result.resultDescription = failure;
    }
    
    return result;
}


@end
