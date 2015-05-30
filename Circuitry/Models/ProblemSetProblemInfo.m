//
//  ProblemSetProblemInfo.m
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ProblemSetProblemInfo.h"
#import "ProblemSet.h"

@interface ProblemSetProblemInfo()
@property (nonatomic) NSDictionary *dictionary;
@end
@implementation ProblemSetProblemInfo


- (instancetype) initWithProblemNumber:(NSUInteger)problemNumber dictionary:(NSDictionary *)dictionary;
    self = [super init];
    _dictionary = dictionary;
    _name = dictionary[@"name"];
    _title = dictionary[@"title"];
    _imageName = dictionary[@"image"];
    _problemIndex = problemIndex;
    
    _visible = NO;
    _completed = NO;
    _accessible = NO;
    
    return self;
}
@end
