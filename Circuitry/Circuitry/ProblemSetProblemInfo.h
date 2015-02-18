//
//  ProblemSetProblemInfo.h
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@class ProblemSet;
@interface ProblemSetProblemInfo : NSObject
@property (nonatomic, readonly) NSUInteger problemIndex;
@property (nonatomic, readonly) NSString *title;

@property (nonatomic) BOOL isCompleted;
@property (nonatomic) BOOL isAccessible;
@property (nonatomic, readonly) BOOL isVisible;

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSURL *documentURL;
@property (nonatomic, readonly) ProblemSet *set;

- (instancetype) initWithProblemIndex:(NSUInteger)problemIndex title:(NSString *)title completed:(BOOL)completed accessible:(BOOL)accessible visible:(BOOL)visible imageName:(NSString *)imageName documentUrl:(NSURL *)documentURL set:(ProblemSet *)set;
@end
