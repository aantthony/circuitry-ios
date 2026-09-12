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
@property (nonatomic) NSUserDefaults *defaults;
@end

static NSString *kDefaultsCurrentLevelIndex = @"CurrentLevelIndex";
static NSString *kCompletedProblems = @"CompletedProblemPaths";
static NSString *kAllProblemsUnlocked = @"AllProblemsUnlocked";

@implementation ProblemSet

+ (instancetype) mainSet {
    NSString *directoryPath = [[NSBundle mainBundle] pathForResource:@"Problems" ofType:nil];
    return [[ProblemSet alloc] initWithDirectoryPath:directoryPath];
}

- (void) unlockAll {
    [self.defaults setBool:YES forKey:kAllProblemsUnlocked];
    [self refresh];
}

- (void) reset {
    [self.defaults setInteger:0 forKey:kDefaultsCurrentLevelIndex];
    [self.defaults setObject:@[] forKey:kCompletedProblems];
    [self.defaults setBool:NO forKey:kAllProblemsUnlocked];
    [self refresh];
}

+ (NSDictionary *) loadIndexAtUrl:(NSURL *) url {
    NSInputStream *stream = [[NSInputStream alloc] initWithURL:url];
    [stream open];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:NULL];
    return data;
}

- (ProblemSet *) initWithDirectoryPath:(NSString *) directoryPath {
    return [self initWithDirectoryPath:directoryPath defaults:NSUserDefaults.standardUserDefaults];
}

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath defaults:(NSUserDefaults *)defaults {
    self = [super init];
    if (!self) return nil;
    _defaults = defaults;
    NSURL *baseUrl = [NSURL fileURLWithPath:directoryPath isDirectory:YES];
    NSDictionary *index = [ProblemSet loadIndexAtUrl:[baseUrl URLByAppendingPathComponent:@"index.json"]];
    
    NSMutableArray *items = [NSMutableArray array];
    NSUInteger i = 0;
    
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

// Store stable paths so appending or reordering levels cannot grant completion.
- (void)migrateLegacyProgressIfNeeded {
    if ([self.defaults objectForKey:kCompletedProblems] != nil) return;
    NSInteger legacyIndex = [self.defaults integerForKey:kDefaultsCurrentLevelIndex];
    // Old "unlock all" saves (999), and older oversized indices, must not
    // complete newly added levels. The original catalog had 21 visible levels.
    NSInteger count = legacyIndex > 22 ? 21 : MAX(0, legacyIndex);
    NSArray *legacyPaths = @[@"001", @"002", @"003", @"004", @"005", @"006",
        @"007", @"008", @"009", @"011", @"012", @"013", @"014", @"015",
        @"016", @"017", @"018", @"020", @"021", @"022", @"023", @"024"];
    [self.defaults setObject:[legacyPaths subarrayWithRange:NSMakeRange(0, count)]
                     forKey:kCompletedProblems];
    if (legacyIndex > 22) [self.defaults setBool:YES forKey:kAllProblemsUnlocked];
}

- (void) refresh {
    [self migrateLegacyProgressIfNeeded];
    NSSet *completed = [NSSet setWithArray:[self.defaults arrayForKey:kCompletedProblems]];
    BOOL allUnlocked = [self.defaults boolForKey:kAllProblemsUnlocked];
    BOOL previousCompleted = YES;
    for (ProblemSetProblemInfo *info in self.problems) {
        info.isCompleted = [completed containsObject:info.documentURL.lastPathComponent];
        info.isAccessible = allUnlocked || previousCompleted || info.isCompleted;
        previousCompleted = info.isCompleted;
    }
}

- (void) didCompleteProblem:(ProblemSetProblemInfo *)problemInfo {
    if (![self.problems containsObject:problemInfo]) return;
    [self migrateLegacyProgressIfNeeded];
    NSMutableSet *completed = [NSMutableSet setWithArray:[self.defaults arrayForKey:kCompletedProblems]];
    [completed addObject:problemInfo.documentURL.lastPathComponent];
    [self.defaults setObject:[[completed allObjects] sortedArrayUsingSelector:@selector(compare:)]
                     forKey:kCompletedProblems];
    [self refresh];
}

- (ProblemSetProblemInfo *) problemAfterProblem:(ProblemSetProblemInfo *)info {
    NSUInteger nextIndex = info.problemIndex + 1;
    if (nextIndex >= _problems.count) return nil;
    return [_problems objectAtIndex:nextIndex];
}

@end
