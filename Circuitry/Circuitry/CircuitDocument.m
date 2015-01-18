//
//  CircuitDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitDocument.h"
#import "AppDelegate.h"

@interface CircuitDocument() <NSURLSessionTaskDelegate>

@end

@implementation CircuitDocument
- (void) setProblemInfo:(ProblemSetProblemInfo *)problemInfo {
    _isProblem = problemInfo != nil;
    _problemInfo = problemInfo;
}
- (instancetype) initWithFileURL:(NSURL *)url {
    return [super initWithFileURL:url];
}
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSError *err;
    
    if ([typeName isEqualToString:@"public.json"]) {
        NSDictionary *full = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&err];
        
        _circuit = [[Circuit alloc] initWithPackage:full items:full[@"items"]];
        if (err) return NO;
        return YES;
    }
    
    NSFileWrapper *wrapper = contents;
    NSDictionary *files = [wrapper fileWrappers];

    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:[files[@"package.json"] regularFileContents] options:0 error:&err];
    if (err) return NO;
    
    NSArray *items = package[@"items"];
    
    if (!items) {
        items = [NSJSONSerialization JSONObjectWithData:[files[@"items.json"] regularFileContents] options:0 error:&err];
        if (err) return NO;
    }
    
//    _screenshot = [files[@"Default@2x~ipad.jpg"] regularFileContents];
     
    _circuit = [[Circuit alloc] initWithPackage:package items: items];
    
    return YES;
}


- (NSArray *) exportItems {
    
    NSMutableArray *items = [NSMutableArray array];
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:object->type->numOutputs];
        for(int i = 0; i < object->type->numOutputs; i++) {
            NSMutableArray *linksFromOutlet = [NSMutableArray array];
            CircuitLink *link = object->outputs[i];
            while (link) {
                [linksFromOutlet addObject:@[[MongoID stringWithId:link->target->id], @(link->targetIndex)]];
                link = link->nextSibling;
            }
            [outputs addObject:linksFromOutlet];
        }
        
        NSString *name = nil;
        if (object->name) {
            name = [NSString stringWithUTF8String:object->name];
        }
        [items addObject:@{
                           @"type": [NSString stringWithUTF8String:object->type->id],
                           @"_id": [MongoID stringWithId:object->id],
                           @"pos": @[@(object->pos.x), @(object->pos.y), @(object->pos.z)],
                           @"name": name ? name : @"",
                           @"in": @(object->in),
                           @"out": @(object->out),
                           @"outputs": outputs
                           }];
    }];
    return items;
}


- (NSDictionary *) exportPackageDictionaryWithoutItems {
    NSMutableArray *testsArray = [NSMutableArray arrayWithCapacity:_circuit.tests.count];
    [_circuit.tests enumerateObjectsUsingBlock:^(CircuitTest *test, NSUInteger idx, BOOL *stop) {
        [testsArray addObject:@{
                                @"name": test.name,
                                @"inputs": test.inputIds,
                                @"outputs": test.outputIds,
                                @"spec": test.spec
                                }];
    }];
    
    return @{
        @"_id": [MongoID stringWithId:_circuit.id],
        @"name": _circuit.name,
        @"version": _circuit.version,
        @"description": _circuit.userDescription,
        @"title": _circuit.title,
        @"author": _circuit.author,
        @"license": _circuit.license,
        @"engines": @{@"circuitry": @">=0.0"},
        @"tests" : testsArray,
        @"meta": _circuit.meta
    };
    
}



- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    if (self.isProblem) {
        [NSException raise:@"Attempted to modify problem" format:@""];
    }
//    if (!_circuit) {
//        *outError = [NSError errorWithDomain:@"au.id.af" code:501 userInfo:@{@"name": @"Circuit does not exist"}];
//        return nil;
//    }
    if ([typeName isEqualToString:@"public.json"]) {
        NSMutableDictionary *dict = [[self exportPackageDictionaryWithoutItems] mutableCopy];
        dict[@"items"] = [self exportItems];
        // Export the entire circuit into a single JSON object:
        return [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    }

    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    NSData *metaJson = [NSJSONSerialization dataWithJSONObject:[self exportPackageDictionaryWithoutItems] options:0 error:NULL];
    NSData *itemsJSON = [NSJSONSerialization dataWithJSONObject:[self exportItems] options:0 error:NULL];

    [wrapper addRegularFileWithContents:metaJson preferredFilename:@"package.json"];
    [wrapper addRegularFileWithContents:itemsJSON preferredFilename:@"items.json"];
//    [wrapper addRegularFileWithContents:_screenshot preferredFilename:@"Default@2x~ipad.jpg"];
    return wrapper;
}

- (void) publish {
    NSData *data = [self contentsForType:@"public.json" error:NULL];
    NSString *path = [NSString stringWithFormat:@"circuit/%@", [MongoID stringWithId:_circuit.id]];
    NSURL *requestURL = [[NSURL URLWithString:nil] URLByAppendingPathComponent:path];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:5.0];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setURL:requestURL];
    
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"done");
//        completionHandler(error);
    }];
    
    [task resume];

}

@end
