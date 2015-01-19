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
//    __block CircuitTest *blockSelf = self;
    [_inputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *circuitObject = [obj pointerValue];
        if (circuitObject == NULL) {
            NSLog(@"Input Nodes: %@", _inputNodes);
//            NSLog(@"idx: %d", idx);
        }
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

- (NSArray *) inputNames {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.inputNodes.count];
    [self.inputNodes enumerateObjectsUsingBlock:^(NSValue *obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *inputNode = [obj pointerValue];
        if (!inputNode || !inputNode->name) {
            [array addObject:@"?"];
            return;
        }
        NSString *str = [NSString stringWithUTF8String:inputNode->name];
        [array addObject:str];
    }];
    return [array copy];
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
    
    NSMutableArray *checks = [NSMutableArray arrayWithCapacity:_spec.count];
    
    [_spec enumerateObjectsUsingBlock:^(NSArray *inputOutputPair, NSUInteger idx, BOOL *stop) {
        NSArray *inputStates = inputOutputPair[0];
        NSArray *outputStates = inputOutputPair[1];
        
        // Apply input state:
        [inputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * inputNode = [_inputNodes[i] pointerValue];
            inputNode->out = [obj intValue];
            
            [circuit performWriteBlock:^(CircuitInternal *internal) {
                CircuitObjectSetOutput(internal, inputNode, [obj intValue]);
            }];
        }];

        [circuit simulate:512];
        
        __block BOOL isMatchForInput = YES;
        // Validate output state:
        [outputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * outputNode = [_outputNodes[i] pointerValue];
            int expected = [obj intValue];
            if (outputNode->in != expected) {
                pass = NO;
                isMatchForInput = NO;
                NSString *inputStateSpecification = [inputStates componentsJoinedByString:@", "];
                NSString *outputStateSpecification = [outputStates componentsJoinedByString:@", "];
                
                if (failure) {
                    failure = [failure stringByAppendingString:@"\n"];
                }
                failure = [failure stringByAppendingFormat:@"f(%@) == (%@) failed: expected %s to equal %d, but got %d instead.", inputStateSpecification, outputStateSpecification, outputNode->name, expected, outputNode->in];
                
                //*stop = YES;
            }
        }];
        
        CircuitTestResultCheck *check = [[CircuitTestResultCheck alloc] initWithInputs:inputStates expectedOutputs:outputStates match:isMatchForInput];
        
        [checks addObject:check];
        
        //if (!pass) *stop = YES;

    }];
    
    // Re-apply inital input state:
    [circuit performWriteBlock:^(CircuitInternal *internal) {
        
        [initalStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * inputNode = [_inputNodes[i] pointerValue];
            CircuitObjectSetOutput(internal, inputNode, [obj intValue]);
        }];
    }];

    
    NSString *rDescription = pass ? @"Passed." : failure;
    
    CircuitTestResult *result = [[CircuitTestResult alloc] initWithResultDescription:rDescription passed:pass checks:checks inputNames:self.inputNames];
    return result;
}


@end
