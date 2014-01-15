//
//  Toolbelt.h
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "ImageAtlas.h"

@interface Toolbelt : Drawable

- (id) initWithAtlas:(ImageAtlas *)atlas;
- (CGRect) bounds;
@end
