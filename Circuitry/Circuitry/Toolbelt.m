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
#import "ToolbeltItem.h"

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
    BOOL _visible;
    BOOL _visibleAnimating;
    float _visibleAnimationOffsetX;
    NSArray *_items;
    int _instanceCount;
    CGFloat _currentObjectX;
}
@property (strong, nonatomic) NSArray *gates;
@property (strong, nonatomic) Sprite *sprite;
@property (strong, nonatomic) Sprite *gateSprite;
@property BatchedSprite *batcher;
@end

@implementation Toolbelt

static SpriteTexturePos symbolOR;
static SpriteTexturePos symbolNOR;
static SpriteTexturePos symbolXOR;
static SpriteTexturePos symbolXNOR;
static SpriteTexturePos symbolAND;
static SpriteTexturePos symbolNAND;
static SpriteTexturePos symbolNOT;
static SpriteTexturePos gateOutletInactive;

- (NSArray *) items {
    return _items;
}
- (void) setItems:(NSArray *)items {
    _items = items;
    [self bufferInstances];
}
- (id) initWithAtlas:(ImageAtlas *)atlas {
    _visible = YES;
    _visibleAnimationOffsetX = 0.0;
    _visibleAnimating = NO;
    _instanceCount = 0;
    _items = [NSArray arrayWithObjects: nil];
    
    self = [super init];
    self.gates = [NSArray arrayWithObjects:[GateObject gateObjectWithId: @"xor" count: 20], nil];
    GLKTextureInfo *texture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Toolbelt@2x" withExtension:@"png"]];
    _sprite = [[Sprite alloc] initWithTexture:texture];
    GLKTextureInfo *gateTexture = [Sprite textureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"OR-gate@2x" withExtension:@"png"]];
    _gateSprite = [[Sprite alloc] initWithTexture:gateTexture];
    _spriteListItem = [atlas positionForSprite:@"listitem@2x"];
    
    symbolOR = [atlas positionForSprite:@"symbol-or@2x"];
    symbolNOR = [atlas positionForSprite:@"symbol-nor@2x"];
    symbolXOR = [atlas positionForSprite:@"symbol-xor@2x"];
    symbolXNOR = [atlas positionForSprite:@"symbol-xnor@2x"];
    symbolAND = [atlas positionForSprite:@"symbol-and@2x"];
    symbolNAND = [atlas positionForSprite:@"symbol-nand@2x"];
    symbolNOT = [atlas positionForSprite:@"symbol-not@2x"];
    gateOutletInactive = [atlas positionForSprite: @"inactive@2x"];
    
    _capacity = 50;
    
    _batcher = [[BatchedSprite alloc] initWithTexture:atlas.texture capacity:_capacity];
    
    _currentObjectX = 0;
    _instances = malloc(sizeof(BatchedSpriteInstance) * _capacity);
    [self bufferInstances];
    return self;
}


- (SpriteTexturePos) textureForProcess:(CircuitProcess *)process {
    Circuit *_circuit = _viewport.circuit;
    CircuitProcess *OR  =[_circuit getProcessById:@"or"];
    CircuitProcess *NOR =[_circuit getProcessById:@"nor"];
    CircuitProcess *XOR =[_circuit getProcessById:@"xor"];
    CircuitProcess *XNOR=[_circuit getProcessById:@"xnor"];
    CircuitProcess *AND =[_circuit getProcessById:@"and"];
    CircuitProcess *NAND=[_circuit getProcessById:@"nand"];
    CircuitProcess *NOT =[_circuit getProcessById:@"not"];
    
    if (process == OR) return symbolOR;
    else if (process == NOR) return symbolNOR;
    else if (process == XOR) return symbolXOR;
    else if (process == XNOR) return symbolXNOR;
    else if (process == AND) return symbolAND;
    else if (process == NAND) return symbolNAND;
    else if (process == NOT) return symbolNOT;
    else return symbolAND;
    
}

GLKVector3 offsetForOutlet(CircuitProcess *process, int index);

GLKVector3 offsetForInlet(CircuitProcess *process, int index);

- (void) bufferInstances {
    __block int i = 0;
    [_items enumerateObjectsUsingBlock:^(ToolbeltItem *obj, NSUInteger idx, BOOL *stop) {
        BatchedSpriteInstance *instance = &_instances[i++];
        instance->tex = _spriteListItem;
        instance->x = 0.0;
        instance->y = idx * _spriteListItem.height;

    }];
    
    [_items enumerateObjectsUsingBlock:^(ToolbeltItem *obj, NSUInteger idx, BOOL *stop) {
        BatchedSpriteInstance *instance = &_instances[idx];
        
        BatchedSpriteInstance *symbolI = &_instances[i++];
        CircuitProcess *type = obj.type;
        symbolI->tex = [self textureForProcess:obj.type];
        symbolI->x = 0.0;
        symbolI->y = idx * _spriteListItem.height;
        
        for(int ni = 0; ni < type->numInputs; ni++) {
            BatchedSpriteInstance *inlet = &_instances[i++];
            GLKVector3 dotPos = offsetForInlet(type, ni);
            inlet->x = instance->x + dotPos.x;
            inlet->y = instance->y + dotPos.y;
            inlet->tex = gateOutletInactive;
        }
        
        for(int ni = 0; ni < type->numOutputs; ni++) {
            BatchedSpriteInstance *inlet = &_instances[i++];
            GLKVector3 dotPos = offsetForOutlet(type, ni);
            inlet->x = instance->x + dotPos.x;
            inlet->y = instance->y + dotPos.y;
            inlet->tex = gateOutletInactive;
        }
    }];
    _instanceCount = i;
    [_batcher buffer:_instances FromIndex:0 count:_instanceCount];

}

- (BOOL) visible {
    return _visible;
}

- (void) setVisible:(BOOL)value {
    if (value != _visible) {
        _visibleAnimating = YES;
        _visible = value;
    }
}

- (void) setCurrentObjectX:(CGFloat) x {
    _currentObjectX = x;
}

- (void) update: (NSTimeInterval) dt {
    if (_visibleAnimating) {
        float targetX = _visible ? 0.0 : -350.0;
        _visibleAnimationOffsetX += 12.0 * dt * (targetX - _visibleAnimationOffsetX);
    }
}

static float devicePixelRatio = 2.0;

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    GLKMatrixStackPush(stack);
    GLKMatrixStackTranslate(stack, _visibleAnimationOffsetX, 0.0, 0.0);

    BatchedSpriteInstance *instance = &_instances[2];
    instance->x = devicePixelRatio * _currentObjectX;
    [_batcher buffer:_instances FromIndex:0 count:20];
    [_batcher drawIndices:0 count:_instanceCount WithTransform:GLKMatrixStackGetMatrix4(stack)];
    GLKMatrixStackPop(stack);
}

- (CGRect) bounds {
    float devicePixelRatio = 2.0;
    return CGRectMake(_visibleAnimationOffsetX, 0, _spriteListItem.width / devicePixelRatio, 1024.0);
}



@end
