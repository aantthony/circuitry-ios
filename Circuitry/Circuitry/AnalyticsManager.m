//
//  AnalyticsManager.m
//  Circuitry
//
//  Created by Anthony Foster on 16/01/2015.
//  Copyright (c) 2015 Circuitry. All rights reserved.
//

#import "AnalyticsManager.h"
#import "Analytics.h"
#import "CircuitDocument.h"
#import "CircuitTestResult.h"
#import "ProblemSetProblemInfo.h"

@implementation AnalyticsManager

+ (instancetype) shared {
    static id shared = nil;
    if (!shared) shared = [self new];
    return shared;
}
- (NSDictionary *) forDocument:(CircuitDocument *)document {
    if (!document) return nil;
    NSMutableDictionary *p = [NSMutableDictionary new];
    if (document.circuit.name) {
        p[@"Name"] = document.circuit.name;
    }
    if (document.circuit.version) {
        p[@"Doc Version"] = document.circuit.version;
    }
    if (document.circuit.title) {
        p[@"Title"] = document.circuit.title;
    }
    if (document.circuit.author) {
        p[@"Author"]  = document.circuit.author;
    }
    
    if (document.isProblem) {
        p[@"Problem"]       = @(document.isProblem);
        p[@"Problem Index"] = @(document.problemInfo.problemIndex);
        p[@"Problem Title"] = document.problemInfo.title;
    }
    
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
