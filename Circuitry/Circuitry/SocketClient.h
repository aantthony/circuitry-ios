//
//  SocketClient.h
//  Circuitry
//
//  Created by Anthony Foster on 11/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketClient : NSObject
+ (SocketClient *) sharedInstance;

- (void) sendEvent:(NSString *) eventName withData:(id)data;
- (void) sendEvent:(NSString *) eventName withData:(id)data andAcknowledge:(void (^)(id err, id response))block;

@end
