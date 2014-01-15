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
#import "BatchedSprite.h"

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

@interface Toolbelt () {
    SpriteTexturePos _spriteListItem;
    BatchedSpriteInstance *_instances;
    int _capacity;
}
@property (strong, nonatomic) NSArray *gates;
@property (strong, nonatomic) Sprite *sprite;
@property (strong, nonatomic) Sprite *gateSprite;
@property BatchedSprite *batcher;
@end

@implementation Toolbelt


- (id) initWithAtlas:(ImageAtlas *)atlas {
    self = [super init];
    self.gates = [NSArray arrayWithObjects:[GateObject gateObjectWithId: @"xor" count: 20], nil];
    GLKTextureInfo *texture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Toolbelt@2x" withExtension:@"png"]];
    _sprite = [[Sprite alloc] initWithTexture:texture];
    GLKTextureInfo *gateTexture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"OR-gate@2x" withExtension:@"png"]];
    _gateSprite = [[Sprite alloc] initWithTexture:gateTexture];
    _spriteListItem = [atlas positionForSprite:@"listitem@2x"];
    _capacity = 50;
    
    _batcher = [[BatchedSprite alloc] initWithTexture:atlas.texture capacity:_capacity];
    
    _instances = malloc(sizeof(BatchedSpriteInstance) * _capacity);
    
    return self;
}

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    [_sprite drawAtPoint:GLKVector3Make(128, 700, 0) withTransform:GLKMatrixStackGetMatrix4(stack)];
    [_gateSprite drawAtPoint:GLKVector3Make(145, 720, 0) withTransform:GLKMatrixStackGetMatrix4(stack)];
    BatchedSpriteInstance *instance = &_instances[0];
    instance->tex = _spriteListItem;
    instance->x = 0.0;
    instance->y = 0.0;
    [_batcher buffer:_instances FromIndex:0 count:1];
    [_batcher drawIndices:0 count:1 WithTransform:GLKMatrixStackGetMatrix4(stack)];
}

- (CGRect) bounds {
    return CGRectMake(128, 700, 1534 / 2, 136 / 2);
}



@end
