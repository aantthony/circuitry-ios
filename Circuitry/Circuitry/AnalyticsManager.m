//
//  AnalyticsManager.m
//  Circuitry
//
//  Created by Anthony Foster on 16/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import "AnalyticsManager.h"
#import "Analytics.h"
@implementation AnalyticsManager

+ (instancetype) shared {
    static id shared = nil;
    if (!shared) shared = [self new];
    return shared;
}
- (NSDictionary *) forDocument:(CircuitDocument *)document {
    NSMutableDictionary *p = [NSMutableDictionary new];
    p[@"Name"]    = document.circuit.name;
    p[@"Doc Version"] = document.circuit.version;
    p[@"Title"]   = document.circuit.title;
    p[@"Author"]  = document.circuit.author;
    
    p[@"Problem"] = @(document.isProblem);
    
    // User-Generated:
    
    
    
    return p;
}

- (void) track:(NSString *)event properties:(NSDictionary *)properties {
    [[Analytics shared] track:event properties:properties];
}

- (void) trackOpenDocument:(CircuitDocument *)document {
    [self track:@"Open Document" properties:[self forDocument:document]];
}
- (void) trackStartProblem:(CircuitDocument *)document {
    [self track:@"Start Problem" properties:[self forDocument:document]];
}
- (void) trackCheckProblem:(CircuitDocument *)document withResult:(CircuitTestResult *)result {
    NSMutableDictionary *dict = [[self forDocument:document] mutableCopy];
    if (result) {
        dict[@"Failure"] = result.resultDescription;
    }
    [self track:@"Check Problem" properties:dict];
}
- (void) trackFinishProblem:(CircuitDocument *)document {
    [self track:@"Finish Problem" properties:[self forDocument:document]];
}

- (void) trackFinishSplash {
    [self track:@"Finish splash" properties:@{}];
}
@end
