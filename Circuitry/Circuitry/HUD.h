//
//  HUD.h
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Toolbelt.h"
#import "Drawable.h"
#import "Viewport.h"
#import "ImageAtlas.h"

@interface HUD : Drawable

- (id) initWithAtlas:(ImageAtlas *)atlas;

@property (strong, nonatomic) Toolbelt *toolbelt;
@property (strong, nonatomic) Viewport *viewPort;

@end
