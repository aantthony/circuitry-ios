//
//  ToolbeltItem.h
//  Circuitry
//
//  Created by Anthony Foster on 26/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Circuit.h"

@interface ToolbeltItem : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) CircuitProcess *type;
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSInteger remaining;
@end
