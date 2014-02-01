//
//  SocketClient.m
//  Circuitry
//
//  Created by Anthony Foster on 11/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "SocketClient.h"
#import "AppDelegate.h"
#import <socket.IO/SocketIO.h>
#import <socket.IO/SocketIOPacket.h>

@interface SocketClient() <SocketIODelegate> {
    
}
@property SocketIO *socket;

@property NSMutableArray *currentHandlers;

@end
@implementation SocketClient


+ (SocketClient *) sharedInstance {
    static dispatch_once_t onceToken = 0;
    static SocketClient *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [[SocketClient alloc] initSharedInstance];
    });
    
    return instance;
}

- (id) initSharedInstance {
    self = [super init];
    _currentHandlers = [NSMutableArray array];
    _socket = [[SocketIO alloc] initWithDelegate:self];
    [self connect:self];
    return self;
}

- (void) sendEvent:(NSString *) eventName withData:(id)data {
    [_socket sendEvent:eventName withData:data];
}
- (void) sendEvent:(NSString *)eventName withData:(id)data andAcknowledge:(void (^)(id err, id response))block {
    [_currentHandlers addObject:block];
    [_socket sendEvent:eventName withData:data andAcknowledge:^(id args) {
        if (args[0] != [NSNull null]) return block(args[0], nil);
        block(nil, args[1]);
    }];
}


- (void) connect:(id)sender {
    NSURL *baseURL = [AppDelegate baseURL];
    _socket.useSecure = [[baseURL scheme] isEqualToString:@"https"];
    [_socket connectToHost:[baseURL host] onPort:[[baseURL port] intValue]];
    _socket.delegate = self;
}

- (void) socketIODidConnect:(SocketIO *)socket {
    NSLog(@"connected");
}
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    [_currentHandlers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        void (^ myblock)(id, id) = obj;
        myblock(@{@"message":@"Connection to server lost."}, nil);
    }];
    [_currentHandlers removeAllObjects];
    // let's try to reconnect:
    [self connect:socket];
}
- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    NSLog(@"message %@", packet);
}
- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    NSLog(@"json %@", packet);
}
- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    NSArray *args = packet.dataAsJSON[@"args"];
    NSLog(@"event %@: %@", packet.name, args);
    if ([packet.name isEqualToString:@"welcome"]) {
        
    }
}
- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    NSLog(@"message %@", packet);
}
- (void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"socket io error: %@", error);
    [self performSelector:@selector(connect:) withObject:self afterDelay:3.0];
}

@end
