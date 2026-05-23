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
@property (nonatomic) NSArray *acceptedSpecs;
@end
@implementation CircuitTest

- (id) initWithName: (NSString *)name inputs:(NSArray *) inputs outputs: (NSArray *)outputs spec: (NSArray *) spec acceptedSpecs:(NSArray *)acceptedSpecs {
    self = [super init];
    _name = name;
    _inputNodes = inputs;
    _outputNodes = outputs;
    _spec = spec;
    _acceptedSpecs = acceptedSpecs;
    return self;
}

- (NSArray *) inputIds {
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:_inputNodes.count];
//    __block CircuitTest *blockSelf = self;
    [_inputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *circuitObject = [obj pointerValue];
        if (circuitObject == NULL) {
            NSLog(@"Input Nodes: %@", self.inputNodes);
            [ids addObject:[NSNull null]];
        } else {
            [ids addObject: [MongoID stringWithId:circuitObject->id]];
        }
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

- (NSArray *) namesForNodes:(NSArray *)nodes {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:nodes.count];
    [nodes enumerateObjectsUsingBlock:^(NSValue *obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *node = [obj pointerValue];
        if (!node || !node->name[0]) {
            [array addObject:@"-"];
            return;
        }
        NSString *str = [NSString stringWithUTF8String:node->name];
        [array addObject:str];
    }];
    return [array copy];
}

- (NSArray *) inputNames {
    return [self namesForNodes:self.inputNodes];
}

- (NSArray *) outputNames {
    return [self namesForNodes:self.outputNodes];
}

- (NSArray *) allAcceptedSpecs {
    if (!self.acceptedSpecs.count) {
        return @[self.spec];
    }
    return [@[self.spec] arrayByAddingObjectsFromArray:self.acceptedSpecs];
}

- (NSArray *) outputStates {
    NSMutableArray *outputStates = [NSMutableArray arrayWithCapacity:self.outputNodes.count];
    [self.outputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject * outputNode = [obj pointerValue];
        [outputStates addObject:@(outputNode->in)];
    }];
    return outputStates;
}

- (BOOL) actualOutputStates:(NSArray *)actualOutputStates matchSpec:(NSArray *)spec {
    if (actualOutputStates.count != spec.count) {
        return NO;
    }
    for(NSUInteger idx = 0; idx < spec.count; idx++) {
        NSArray *inputOutputPair = spec[idx];
        NSArray *inputStates = inputOutputPair[0];
        NSArray *originalInputStates = self.spec[idx][0];
        if (![inputStates isEqualToArray:originalInputStates]) {
            return NO;
        }
        NSArray *outputStates = inputOutputPair[1];
        if (![actualOutputStates[idx] isEqualToArray:outputStates]) {
            return NO;
        }
    }
    return YES;
}

- (CircuitTestResult *) runAndSimulate:(Circuit *)circuit {
    // determine initial input state:
    NSMutableArray *initalStates = [NSMutableArray arrayWithCapacity:_inputNodes.count];
    [_inputNodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject * inputNode = [obj pointerValue];
        [initalStates addObject:@(inputNode->out)];
    }];

    NSMutableArray *actualOutputStates = [NSMutableArray arrayWithCapacity:_spec.count];
    
    [_spec enumerateObjectsUsingBlock:^(NSArray *inputOutputPair, NSUInteger idx, BOOL *stop) {
        NSArray *inputStates = inputOutputPair[0];
        
        // Apply input state:
        [inputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * inputNode = [self.inputNodes[i] pointerValue];
            inputNode->out = [obj intValue];

            [circuit performWriteBlock:^(CircuitInternal *internal) {
                CircuitObjectSetOutput(internal, inputNode, [obj intValue]);
            }];
        }];

        [circuit simulate:512];
        [actualOutputStates addObject:[self outputStates]];

    }];

    // Re-apply inital input state:
    [circuit performWriteBlock:^(CircuitInternal *internal) {
        
        [initalStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            CircuitObject * inputNode = [self.inputNodes[i] pointerValue];
            CircuitObjectSetOutput(internal, inputNode, [obj intValue]);
        }];
    }];

    NSArray *matchedSpec = nil;
    for(NSArray *acceptedSpec in [self allAcceptedSpecs]) {
        if ([self actualOutputStates:actualOutputStates matchSpec:acceptedSpec]) {
            matchedSpec = acceptedSpec;
            break;
        }
    }

    BOOL pass = matchedSpec != nil;
    NSArray *resultSpec = matchedSpec ?: self.spec;
    NSMutableArray *checks = [NSMutableArray arrayWithCapacity:resultSpec.count];
    NSMutableArray *failureMessages = [NSMutableArray array];

    [resultSpec enumerateObjectsUsingBlock:^(NSArray *inputOutputPair, NSUInteger idx, BOOL *stop) {
        NSArray *inputStates = inputOutputPair[0];
        NSArray *outputStates = inputOutputPair[1];
        NSArray *actualOutputs = actualOutputStates[idx];
        __block BOOL isMatchForInput = YES;

        [outputStates enumerateObjectsUsingBlock:^(id obj, NSUInteger i, BOOL *stop) {
            int expected = [obj intValue];
            int actual = [actualOutputs[i] intValue];
            if (actual != expected) {
                isMatchForInput = NO;
                CircuitObject * outputNode = [self.outputNodes[i] pointerValue];
                NSString *inputStateSpecification = [inputStates componentsJoinedByString:@", "];
                NSString *outputStateSpecification = [outputStates componentsJoinedByString:@", "];
                [failureMessages addObject:[NSString stringWithFormat:@"f(%@) == (%@) failed: expected %s to equal %d, but got %d instead.", inputStateSpecification, outputStateSpecification, outputNode->name, expected, actual]];
            }
        }];
        
        CircuitTestResultCheck *check = [[CircuitTestResultCheck alloc] initWithInputs:inputStates expectedOutputs:outputStates match:isMatchForInput];
        
        [checks addObject:check];
    }];
    
    NSString *failure = [failureMessages componentsJoinedByString:@"\n"];
    NSString *rDescription = pass ? @"Passed." : failure;
    
    CircuitTestResult *result = [[CircuitTestResult alloc] initWithResultDescription:rDescription passed:pass checks:checks inputNames:self.inputNames outputNames:self.outputNames];
    return result;
}


@end
