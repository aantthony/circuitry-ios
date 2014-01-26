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
@property NSString *name;
@property CircuitProcess *type;
@property NSUInteger count;
@property NSInteger remaining;
@end
