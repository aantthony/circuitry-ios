//
//  CircuitDocument.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "CircuitDocument.h"

@implementation CircuitDocument
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"Loading....");
    NSString *err;
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:contents mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&err];
    
    if (err) [NSException exceptionWithName:@"Could not load data" reason:err userInfo:@{}];
    
    _circuit = [[Circuit alloc] initWithDictionary:dict];
    return YES;
}
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {

    NSError *err;
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:[_circuit toDictionary] format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    NSLog(@"SAVED");
    return data;
}
@end
