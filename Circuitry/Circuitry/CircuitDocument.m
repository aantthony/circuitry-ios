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
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    _circuit = [Circuit circuitWithJSON:contents];
    return YES;
    NSLog(@"Loading....");
    NSString *err;
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:contents mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&err];
    
    if (err) [NSException exceptionWithName:@"Could not load data" reason:err userInfo:@{}];
    
    _circuit = [[Circuit alloc] initWithDictionary:dict];
    return YES;
}
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {

    return [_circuit toJSON];
    NSError *err;
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:[_circuit toDictionary] format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    NSData *json = [_circuit toJSON];
    
    NSLog(@"SAVED %d / %d", data.length, json.length);
    return data;
}

- (void) publish {
    NSData *data = [self contentsForType:@"json" error:NULL];
    NSString *path = [NSString stringWithFormat:@"circuit/%@", [MongoID stringWithId:_circuit.id]];
    NSURL *requestURL = [[AppDelegate baseURL] URLByAppendingPathComponent:path];
    
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
