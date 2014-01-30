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

@interface Toolbelt () {
    SpriteTexturePos _spriteListItem;
    SpriteTexturePos _spriteListItemB;
    BatchedSpriteInstance *_instances;
    int _capacity;
    BOOL _visible;
    BOOL _visibleAnimating;
    float _visibleAnimationOffsetX;
    NSArray *_items;
    int _instanceCount;
    CGFloat _currentObjectX;
    CGFloat _actualCurrentObjectX;
    CGFloat _actualCurrentObjectFollowX;
    int _currentObjectIndex;
    BOOL _itemSelected;
    BOOL _currentObjectXAnimating;
}
@property (strong, nonatomic) NSArray *gates;
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
    _currentObjectIndex = -1;
    _visible = YES;
    _visibleAnimationOffsetX = 0.0;
    _actualCurrentObjectFollowX = _actualCurrentObjectX = 0.0;
    _visibleAnimating = NO;
    _currentObjectXAnimating = NO;
    _instanceCount = 0;
    _items = [NSArray arrayWithObjects: nil];
    
    _itemSelected = NO;
    
    self = [super init];

    _spriteListItem = [atlas positionForSprite:@"listitem@2x"];
    _spriteListItemB = [atlas positionForSprite:@"listitemb@2x"];
    
    symbolOR = [atlas positionForSprite:@"symbol-or@2x"];
    symbolNOR = [atlas positionForSprite:@"symbol-nor@2x"];
    symbolXOR = [atlas positionForSprite:@"symbol-xor@2x"];
    symbolXNOR = [atlas positionForSprite:@"symbol-xnor@2x"];
    symbolAND = [atlas positionForSprite:@"symbol-and@2x"];
    symbolNAND = [atlas positionForSprite:@"symbol-nand@2x"];
    symbolNOT = [atlas positionForSprite:@"symbol-not@2x"];
    gateOutletInactive = [atlas positionForSprite: @"inactive@2x"];
    
    _capacity = 100;
    
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
static int i = 0;
- (void) drawAt:(ToolbeltItem *)obj index:(int) idx frameInstance:(BatchedSpriteInstance*)instance  {
    
    BatchedSpriteInstance *symbolI = &_instances[i++];
    CircuitProcess *type = obj.type;
    symbolI->tex = [self textureForProcess:obj.type];
    symbolI->x = instance->x + 9.0;
    symbolI->y = instance->y + 0.0;
    
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
}

- (void) bufferInstances {
    i = 0;
    [_items enumerateObjectsUsingBlock:^(ToolbeltItem *obj, NSUInteger idx, BOOL *stop) {
        BatchedSpriteInstance *instance = &_instances[i++];
        instance->tex = _spriteListItem;
        instance->x = 0.0;
        instance->y = idx * _spriteListItem.height;
    }];
    
    [_items enumerateObjectsUsingBlock:^(ToolbeltItem *obj, NSUInteger idx, BOOL *stop) {
        BatchedSpriteInstance *instance = &_instances[idx];
        [self drawAt:obj index:idx frameInstance:instance];
    }];
    
    if (_currentObjectIndex != -1) {
        
        BatchedSpriteInstance *under = &_instances[i++];
        under->tex = _spriteListItemB;
        under->x = 0.0;
        under->y = _currentObjectIndex * _spriteListItem.height;
        
        BatchedSpriteInstance *instance = &_instances[i++];
        instance->tex = _spriteListItem;
        instance->x = -_spriteListItem.width + _actualCurrentObjectFollowX * devicePixelRatio;;
        instance->y = _currentObjectIndex * _spriteListItem.height;
        [self drawAt:_items[_currentObjectIndex] index:_currentObjectIndex frameInstance:instance];
        
        
        if (_itemSelected) {
            BatchedSpriteInstance *instance = &_instances[i++];
            instance->tex = _spriteListItem;
            instance->x = _actualCurrentObjectX * devicePixelRatio;
            instance->y = _currentObjectIndex * _spriteListItem.height;
            
            [self drawAt:_items[_currentObjectIndex] index:_currentObjectIndex frameInstance:instance];
            
        }
    }
    _instanceCount = i;
    [_batcher buffer:_instances FromIndex:0 count:_instanceCount];

}

- (float) listWidth {
    return _spriteListItem.width / devicePixelRatio;
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

- (void) updateDynamicInstances {
    [self bufferInstances];
}

- (void) setCurrentObjectX:(CGFloat) x {
    _currentObjectX = x;
    _currentObjectXAnimating = YES;
    [self updateDynamicInstances];
}

- (NSInteger) currentObjectIndex {
    return _currentObjectIndex;
}
- (void) setCurrentObjectIndex:(NSInteger)itemIndex {
    if (itemIndex == -1) {
        _currentObjectX = self.listWidth;
        _itemSelected = NO;
        [self updateDynamicInstances];
        _currentObjectXAnimating = YES;
        return;
    }
    
    if (itemIndex != _currentObjectIndex || !_itemSelected) {
        _itemSelected = YES;
        _currentObjectIndex = itemIndex;
        _actualCurrentObjectX = 0.0;
        _actualCurrentObjectFollowX = 0.0;
        _currentObjectXAnimating = YES;
        [self updateDynamicInstances];
    }
}

- (int) indexAtPosition:(CGPoint) position {
    int index = devicePixelRatio * position.y / _spriteListItem.height;
    if (index >= 0 && index < _items.count) {
        return index;
    }
    return -1;
}

- (int) update: (NSTimeInterval) dt {
    int changes = 0;
    if (_visibleAnimating) {
        float targetX = _visible ? 0.0 : -350.0;
        _visibleAnimationOffsetX += 12.0 * dt * (targetX - _visibleAnimationOffsetX);
        changes ++;
        float diff = fabs(targetX - _visibleAnimationOffsetX);
        if (diff < 0.1) {
            _visibleAnimationOffsetX = targetX;
            _visibleAnimating = NO;
        }
    }
    if (_currentObjectXAnimating) {
        changes++;
        _actualCurrentObjectX += 8.0 * dt * (_currentObjectX - _actualCurrentObjectX);
        _actualCurrentObjectFollowX += 5.0 * dt * (_currentObjectX - _actualCurrentObjectFollowX);
        [self updateDynamicInstances];
        float diff = fabs(_currentObjectX - _actualCurrentObjectX) + fabs(_currentObjectX - _actualCurrentObjectFollowX);
        if (diff < 0.1) {
            _currentObjectXAnimating = NO;
            _actualCurrentObjectX = _currentObjectX;
            _actualCurrentObjectFollowX = _currentObjectX;
            _currentObjectXAnimating = NO;
        }
    }
    return changes;
}

static float devicePixelRatio = 2.0;

- (void) drawWithStack:(GLKMatrixStackRef)stack {
    GLKMatrixStackPush(stack);
    GLKMatrixStackTranslate(stack, _visibleAnimationOffsetX, 0.0, 0.0);

//    [_batcher buffer:_instances FromIndex:0 count:20];
    [_batcher drawIndices:0 count:_instanceCount WithTransform:GLKMatrixStackGetMatrix4(stack)];
    GLKMatrixStackPop(stack);
}

- (CGRect) bounds {
    float devicePixelRatio = 2.0;
    return CGRectMake(_visibleAnimationOffsetX, 0, _spriteListItem.width / devicePixelRatio, 1024.0);
}



@end
