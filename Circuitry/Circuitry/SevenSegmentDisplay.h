//
//  SevenSegmentDisplay.h
//  Circuitry
//
//  Created by Anthony Foster on 1/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "BatchedSprite.h"

@interface SevenSegmentDisplay : NSObject
- (SevenSegmentDisplay *) initWithTexture: (GLKTextureInfo *) texture component:(SpriteTexturePos) source;

- (void) drawAt: (GLKVector3) position withInput:(int) input withTransform:(GLKMatrix4) viewProjectionMatrix;
@end
