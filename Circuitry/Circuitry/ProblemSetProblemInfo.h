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

@property (nonatomic) BOOL isCompleted;
@property (nonatomic) BOOL isAccessible;
@property (nonatomic) BOOL isVisible;

@property (nonatomic) NSString *imageName;
@property (nonatomic) NSURL *documentURL;
@property (nonatomic) ProblemSet *set;
@end
