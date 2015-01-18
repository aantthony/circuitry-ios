//
//  CircuitDocument.h
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "Circuit.h"
@class ProblemSetProblemInfo;
@interface CircuitDocument : UIDocument
@property (nonatomic) Circuit *circuit;
@property (nonatomic, readonly) BOOL isProblem;
@property (nonatomic) ProblemSetProblemInfo *problemInfo;
@end
