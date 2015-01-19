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
    
    NSUInteger i = 0;
    for (NSDictionary *p in index[@"problems"]) {
        ProblemSetProblemInfo *info = [ProblemSetProblemInfo new];
        info.problemIndex = i++;
        info.title = p[@"title"];
        
        info.isCompleted = i < 3;
        info.isVisible = YES;
        info.isAccessible = i < 3;
        
        info.set = self;
        info.documentURL = [baseUrl URLByAppendingPathComponent:p[@"path"] isDirectory:YES];
        
        info.imageName = p[@"image"];
        if (!info.imageName) {
            info.imageName = [NSString stringWithFormat:@"level-%@", p[@"path"]];
        }
        
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
