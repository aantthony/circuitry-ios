//
//  Toolbelt.m
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "Toolbelt.h"

@interface GateObject : NSObject
    @property NSString *id;
    @property NSInteger remaining;
    @property NSInteger maximum;

    + (GateObject *) gateObjectWithId:(NSString *)id count:(NSInteger) count;
@end

@implementation GateObject
    + (GateObject *) gateObjectWithId:(NSString *)id count:(NSInteger)count {
        GateObject *o = [[GateObject alloc] init];
        o.maximum = o.remaining = count;
        o.id = id;
        return o;
    }

@end

@interface Toolbelt () {}
    @property (strong, nonatomic) NSArray *gates;

@end

@implementation Toolbelt

- (id) init {
    self = [super init];
    self.gates = [NSArray arrayWithObjects:[GateObject gateObjectWithId: @"xor" count: 20], nil];
    return self;
}

- (void) draw {
    
}



@end
