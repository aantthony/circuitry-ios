//
//  ProblemSet.h
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProblemSetProblemInfo.h"

@interface ProblemSet : NSObject
- (ProblemSet *) initWithDirectoryPath:(NSString *) path;
- (NSArray *) problems;
- (ProblemSetProblemInfo *) problemAfterProblem:(ProblemSetProblemInfo *)info;
@end
