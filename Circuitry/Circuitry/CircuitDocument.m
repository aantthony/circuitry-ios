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
    
    NSError *err;
    
    if ([typeName isEqualToString:@"public.json"]) {
        _circuit = [[Circuit alloc] initWithDictionary:[NSJSONSerialization JSONObjectWithData:contents options:0 error:&err]];
        _screenshot = nil;
        if (err) return NO;
        return YES;
    }
    
    NSFileWrapper *wrapper = contents;
    NSDictionary *files = [wrapper fileWrappers];

    NSDictionary *package = [NSJSONSerialization JSONObjectWithData:[files[@"package.json"] regularFileContents] options:0 error:&err];
    if (err) return NO;
    
    NSArray *items = [NSJSONSerialization JSONObjectWithData:[files[@"items.json"] regularFileContents] options:0 error:&err];
    if (err) return NO;
    
    _screenshot = [files[@"Default@2x~ipad.jpg"] regularFileContents];
    
    _circuit = [[Circuit alloc] initWithPackage:package items: items];
    
    return YES;
}
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {

    if ([typeName isEqualToString:@"public.json"]) {
        return [NSJSONSerialization dataWithJSONObject:[_circuit toDictionary] options:0 error:NULL];
    }

    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    NSData *metaJson = [NSJSONSerialization dataWithJSONObject:[_circuit metadata] options:0 error:NULL];
    NSData *itemsJSON = [NSJSONSerialization dataWithJSONObject:[_circuit toDictionary][@"items"] options:0 error:NULL];

    [wrapper addRegularFileWithContents:metaJson preferredFilename:@"package.json"];
    [wrapper addRegularFileWithContents:itemsJSON preferredFilename:@"items.json"];
    [wrapper addRegularFileWithContents:_screenshot preferredFilename:@"Default@2x~ipad.jpg"];
    
    NSLog(@"saved jpeg of size %d", [_screenshot length]);
    return wrapper;
}

- (void) publish {
    NSData *data = [self contentsForType:@"public.json" error:NULL];
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
