//
//  ProblemSetProblemInfo.h
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//


@interface ProblemSetProblemInfo : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger problemNumber;
@property (nonatomic, readonly) NSString *title;

@property (nonatomic, getter=isCompleted)  BOOL completed;
@property (nonatomic, getter=isAccessible) BOOL accessible;
@property (nonatomic, getter=isVisible)    BOOL visible;

@property (nonatomic, readonly) NSString *imageName;

- (instancetype) initWithProblemNumber:(NSUInteger)problemNumber dictionary:(NSDictionary *)dictionary;
@end
