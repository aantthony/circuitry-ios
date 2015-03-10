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

static NSString *kDefaultsCurrentLevelIndex = @"CurrentLevelIndex";

@implementation ProblemSet

+ (instancetype) mainSet {
    NSString *directoryPath = [[NSBundle mainBundle] pathForResource:@"Problems" ofType:nil];
    return [[ProblemSet alloc] initWithDirectoryPath:directoryPath];
}

+ (NSDictionary *) loadIndexAtUrl:(NSURL *) url {
    NSInputStream *stream = [[NSInputStream alloc] initWithURL:url];
    [stream open];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:NULL];
    return data;
}

- (ProblemSet *) initWithDirectoryPath:(NSString *) directoryPath {
    
    self = [super init];
    NSURL *baseUrl = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
    NSDictionary *index = [ProblemSet loadIndexAtUrl:[baseUrl URLByAppendingPathComponent:@"index.json"]];
    
    NSMutableArray *items = [NSMutableArray array];
    
    NSUInteger playerCurrentLevelIndex = 0;
    NSUInteger i = 0;
    
    playerCurrentLevelIndex = 30;
    
    for (NSDictionary *p in index[@"problems"]) {
        NSUInteger index = i;
        NSURL *url = [baseUrl URLByAppendingPathComponent:p[@"path"] isDirectory:YES];
        
        NSString *imageName = p[@"image"];
        if (!imageName) {
            imageName = [NSString stringWithFormat:@"level-%@", p[@"path"]];
        }
        
        ProblemSetProblemInfo *info = [[ProblemSetProblemInfo alloc] initWithProblemIndex:index title:p[@"title"] completed:NO accessible:NO visible:YES imageName:imageName documentUrl:url set:self];
        if (p[@"hidden"]) continue;
        
        [items addObject:info];
        
        i++;
    }
    _problems = items;
    [self refresh];
    return self;
}

- (NSArray *) problems {
    return _problems;
}

- (void) refresh {
    
    NSUInteger playerCurrentLevelIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrentLevelIndex];
    
    [_problems enumerateObjectsUsingBlock:^(ProblemSetProblemInfo *obj, NSUInteger i, BOOL *stop) {
        BOOL completed = obj.problemIndex < playerCurrentLevelIndex;
        BOOL accessible = obj.problemIndex <= playerCurrentLevelIndex;

        obj.isCompleted = completed;
        obj.isAccessible = accessible;
    }];
}

- (void) didCompleteProblem:(ProblemSetProblemInfo *)problemInfo {
    
    NSUInteger playerCurrentLevelIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrentLevelIndex];
    
    NSUInteger updatedCurrentLevelIndex = problemInfo.problemIndex + 1;
    if (updatedCurrentLevelIndex <= playerCurrentLevelIndex) return;

    [[NSUserDefaults standardUserDefaults] setInteger:playerCurrentLevelIndex forKey:kDefaultsCurrentLevelIndex];
    
    [self refresh];
}

- (ProblemSetProblemInfo *) problemAfterProblem:(ProblemSetProblemInfo *)info {
    NSUInteger nextIndex = info.problemIndex + 1;
    if (nextIndex >= _problems.count) return nil;
    return [_problems objectAtIndex:nextIndex];
}

@end
