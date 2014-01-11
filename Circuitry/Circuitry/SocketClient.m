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

@end
@implementation SocketClient

- (id) init {
    self = [super init];
    
    _socket = [[SocketIO alloc] initWithDelegate:self];
    NSURL *baseURL = [AppDelegate baseURL];
    
    _socket.useSecure = [[baseURL scheme] isEqualToString:@"https"];
    [_socket connectToHost:[baseURL host] onPort:[[baseURL port] intValue]];
    _socket.delegate = self;
    
    return self;
}

- (void) socketIODidConnect:(SocketIO *)socket {
    NSLog(@"connected");
}
- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"disconnect %@", error);
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
}

@end
