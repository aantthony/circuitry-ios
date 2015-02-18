//
//  ProblemSetProblemInfo.m
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ProblemSetProblemInfo.h"
#import "ProblemSet.h"

@implementation ProblemSetProblemInfo

- (instancetype) initWithProblemIndex:(NSUInteger)problemIndex title:(NSString *)title completed:(BOOL)completed accessible:(BOOL)accessible visible:(BOOL)visible imageName:(NSString *)imageName documentUrl:(NSURL *)documentURL set:(ProblemSet *)set {
    self = [super init];
    _problemIndex = problemIndex;
    _title = title;
    _isCompleted = completed;
    _isAccessible = accessible;
    _isVisible = visible;
    _imageName = imageName;
    _documentURL = documentURL;
    _set = set;
    return self;
}
@end
