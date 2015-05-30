//
//  ProblemSet.m
//  Circuitry
//
//  Created by Anthony Foster on 29/11/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ProblemSet.h"

@interface ProblemSet()
@property (nonatomic) NSArray *problems;
@end

static NSString *kDefaultsCompletedProblemNames = @"CompletedProblemIds";

@implementation ProblemSet

+ (instancetype) mainSet {
    NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"problems" withExtension:@"json"]];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [[ProblemSet alloc] initWithDictionary:dict];
}

- (void) unlockAll {
    [self refresh];
}

- (void) reset {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsCompletedProblemNames];
    [self refresh];
}

- (ProblemSet *) initWithDictionary:(NSDictionary *) dictionary {
    
    self = [super init];
    
    NSArray *problemsData = (NSArray *)dictionary;
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:problemsData.count];
    NSUInteger i = 0;
    
    
    for (NSDictionary *p in problemsData) {        
        ProblemSetProblemInfo *info = [[ProblemSetProblemInfo alloc] initWithProblemNumber:i dictionary:p];
        [items addObject:info];
        i++;
    }
    _problems = items;
    [self refresh];
    return self;
}

- (void) refresh {
    NSMutableArray *completedNames = self.completedNames;
    BOOL lastCompleted = YES;
    for(ProblemSetProblemInfo *problem in _problems) {
        problem.completed = [completedNames containsObject:problem.name];
        problem.accessible = problem.completed || lastCompleted;
        problem.visible = YES;
        
        lastCompleted = problem.completed;
    }
}

- (void) didCompleteProblem:(ProblemSetProblemInfo *)problemInfo {
    
    NSMutableArray *completedNames = self.completedNames;
    
    if(![completedNames containsObject:problemInfo.name]) {
        [completedNames addObject:problemInfo.name];
    }
    
    self.completedNames = completedNames;
    
    [self refresh];
}

- (BOOL) hasUserCompletedProblemWithName:(NSString *) problemName {
    return [self.completedNames containsObject:problemName];
}

- (ProblemSetProblemInfo *) problemAfterProblem:(ProblemSetProblemInfo *)info {
    NSUInteger index = [_problems indexOfObject:info];
    if (index == NSNotFound) return nil;
    NSUInteger nextIndex = index + 1;
    if (nextIndex >= _problems.count) {
        return nil;
    }
    return [_problems objectAtIndex:nextIndex];
}

- (BOOL) isItemAvailable:(NSString *)itemName {
    return YES;
}


#pragma mark - Storage

- (NSMutableArray *)completedNames {
    NSArray *existing = [[NSUserDefaults standardUserDefaults] arrayForKey:kDefaultsCompletedProblemNames];
    if (!existing) {
        return [[NSMutableArray alloc] initWithCapacity:1];
    }
    return [existing mutableCopy];
}

- (void) setCompletedNames:(NSArray *)completedNames {
    [[NSUserDefaults standardUserDefaults] setObject:completedNames forKey:kDefaultsCompletedProblemNames];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
