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
    
    for (NSDictionary *p in index[@"problems"]) {
        ProblemSetProblemInfo *info = [ProblemSetProblemInfo new];
        info.title = p[@"title"];
        info.completed = NO;
        info.visible = YES;
        info.set = self;
        info.documentURL = [baseUrl URLByAppendingPathComponent:p[@"path"] isDirectory:YES];
        
        info.imageName = [NSString stringWithFormat:@"level-%@", p[@"path"]];
        
        [items addObject:info];
    }
    _problems = items;
    return self;
}

- (NSArray *) problems {
    return _problems;
}

@end
