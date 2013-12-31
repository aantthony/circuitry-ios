//
//  Sprite.h
//  Circuitry
//
//  Created by Anthony Foster on 16/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ShaderEffect.h"

@interface Sprite : NSObject


+ (void)setContext: (EAGLContext*) context;

+ (GLKTextureInfo *) textureWithContentsOfFile: (NSString *) fileName;

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture atX: (int) x Y:(int) y width:(int)w height: (int) h;

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture;


- (void) drawAtPoint: (CGPoint) point withTransform:(GLKMatrix4) modelViewProjectionMatrix;


@end
