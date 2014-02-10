//
//  CircuitImagePreview.h
//  Circuitry
//
//  Created by Anthony Foster on 10/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Circuit.h"
@interface CircuitImagePreview : NSObject
- (CALayer *) layerForCircuit:(Circuit *) circuit;
- (NSData *) png: (Circuit *) circuit;
@end
