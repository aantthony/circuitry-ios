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

@implementation ProblemSet

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
    
    NSUInteger playerCurrentLevelIndex = 1;
    NSUInteger i = 0;
    
    playerCurrentLevelIndex = 30;
    
    for (NSDictionary *p in index[@"problems"]) {
        NSUInteger index = i++;
        
        BOOL completed = index < playerCurrentLevelIndex;
        BOOL accessible = index <= playerCurrentLevelIndex;

        NSURL *url = [baseUrl URLByAppendingPathComponent:p[@"path"] isDirectory:YES];
        
        NSString *imageName = p[@"image"];
        if (!imageName) {
            imageName = [NSString stringWithFormat:@"level-%@", p[@"path"]];
        }
        
        ProblemSetProblemInfo *info = [[ProblemSetProblemInfo alloc] initWithProblemIndex:index title:p[@"title"] completed:completed accessible:accessible visible:YES imageName:imageName documentUrl:url set:self];
        if (p[@"hidden"]) continue;
        
        [items addObject:info];
    }
    _problems = items;
    return self;
}

- (NSArray *) problems {
    return _problems;
}

- (ProblemSetProblemInfo *) problemAfterProblem:(ProblemSetProblemInfo *)info {
    NSUInteger nextIndex = info.problemIndex + 1;
    if (nextIndex >= _problems.count) return nil;
    return [_problems objectAtIndex:nextIndex];
}

@end
