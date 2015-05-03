//
//  AnalyticsManager.h
//  Circuitry
//
//  Created by Anthony Foster on 16/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

@class CircuitDocument;
@class CircuitTestResult;

@interface AnalyticsManager : NSObject

+ (instancetype) shared;

- (void) trackOpenDocument  :(CircuitDocument *)document;
- (void) trackStartProblem  :(CircuitDocument *)document;
- (void) trackCheckProblem  :(CircuitDocument *)document withResult:(CircuitTestResult *)result;
- (void) trackFinishProblem :(CircuitDocument *)document;
- (void) trackFinishSplash;

@end
