//
//  Toolbelt.m
//  Circuitry
//
//  Created by Anthony Foster on 12/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "Toolbelt.h"
#import "Sprite.h"
#import "Circuit.h"

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
    @property (strong, nonatomic) Sprite *sprite;
    @property (strong, nonatomic) Sprite *gateSprite;

@end

@implementation Toolbelt

- (id) init {
    self = [super init];
    self.gates = [NSArray arrayWithObjects:[GateObject gateObjectWithId: @"xor" count: 20], nil];
    GLKTextureInfo *texture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Toolbelt@2x" withExtension:@"png"]];
    _sprite = [[Sprite alloc] initWithTexture:texture];
    GLKTextureInfo *gateTexture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"OR-gate@2x" withExtension:@"png"]];
    _gateSprite = [[Sprite alloc] initWithTexture:gateTexture];
    return self;
}

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    [_sprite drawAtPoint:GLKVector3Make(128, 700, 0) withTransform:GLKMatrixStackGetMatrix4(stack)];
    [_gateSprite drawAtPoint:GLKVector3Make(145, 720, 0) withTransform:GLKMatrixStackGetMatrix4(stack)];
    
}



@end
