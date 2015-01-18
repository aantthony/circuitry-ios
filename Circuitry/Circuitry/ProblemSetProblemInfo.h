//
//  ProblemSetProblemInfo.h
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@class ProblemSet;
@interface ProblemSetProblemInfo : NSObject
@property (nonatomic) NSUInteger problemIndex;
@property (nonatomic) NSString *title;
@property (nonatomic) BOOL completed;
@property (nonatomic) NSString *imageName;
@property (nonatomic) NSURL *documentURL;
@property (nonatomic) BOOL visible;
@property (nonatomic) ProblemSet *set;
@end
