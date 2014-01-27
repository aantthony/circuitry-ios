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
#import "Viewport.h"

@interface Toolbelt : Drawable

@property Viewport *viewport;

- (id) initWithAtlas:(ImageAtlas *)atlas;
- (CGRect) bounds;
- (BOOL) visible;
- (void) setVisible:(BOOL) value;
- (int) update: (NSTimeInterval) dt;
- (NSArray *) items;
- (void) setItems:(NSArray *)items;
- (void) setCurrentObjectX:(CGFloat) x;
- (NSInteger) currentObjectIndex;
- (void) setCurrentObjectIndex:(NSInteger)itemIndex;
- (int) indexAtPosition:(CGPoint) position;

- (float) listWidth;

@end
