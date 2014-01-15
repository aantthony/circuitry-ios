#import "Viewport.h"

#import "Grid.h"
#import "LinkBezier.h"
#import "Sprite.h"
#import "BatchedSprite.h"

@interface Viewport() {
    GLKMatrix4 _viewMatrix;
    GLKMatrix4 _viewProjectionMatrix;
    GLKMatrix4 _projectionMatrix;
    GLKVector3 _translate;
    GLKVector3 _scale;
    LinkBezier *bezier;
    BatchedSprite *_gateSprites;

    BatchedSpriteInstance *_instances;
    int _capacity;
    int _count;
}
@property Grid *grid;
@end

@implementation Viewport

static SpriteTexturePos gateBackgroundHeight1;
static SpriteTexturePos gateBackgroundHeight2;
static SpriteTexturePos gateOutletInactive;
static SpriteTexturePos gateOutletActive;
static SpriteTexturePos gateOutletActiveConnected;
static SpriteTexturePos gateOutletInactiveConnected;

- (id) initWithContext: (EAGLContext*) context atlas:(ImageAtlas *)atlas {
    self = [self init];
        
    float initialScale = 0.5;
    _translate = GLKVector3Make(0.0, 0.0, 0.0);
    _scale     = GLKVector3Make(initialScale, initialScale, initialScale);
    
    _grid = [[Grid alloc] init];
    
    [_grid setScale:_scale translate:_translate];
    
    [self recalculateMatrices];
    
    
    [ShaderEffect checkError];
    [Sprite setContext: context];
    [ShaderEffect checkError];
    [BatchedSprite setContext: context];
    [ShaderEffect checkError];
    
    _capacity = 10000;
    
    _gateSprites = [[BatchedSprite alloc] initWithTexture:atlas.texture capacity:_capacity];
    
    _instances = malloc(sizeof(BatchedSpriteInstance) * _capacity);
    
    gateBackgroundHeight1 = [atlas positionForSprite: @"single@2x"];
    gateBackgroundHeight2 = [atlas positionForSprite: @"double@2x"];
    gateOutletInactive = [atlas positionForSprite: @"inactive@2x"];
    gateOutletActive = [atlas positionForSprite:  @"active@2x"];
    gateOutletActiveConnected = [atlas positionForSprite: @"activeconnected@2x"];
    gateOutletInactiveConnected = [atlas positionForSprite:  @"inactiveconnected@2x"];
    
    for(int i = 0; i < _capacity; i++) {
        _instances[i].tex = gateBackgroundHeight2;
    }
    
    [ShaderEffect checkError];
    [_gateSprites buffer:_instances FromIndex:0 count:_capacity];
    
    [ShaderEffect checkError];
    bezier = [[LinkBezier alloc] init];
    
    return self;
}
- (void)update {

}

- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix {
    _projectionMatrix = projectionMatrix;
    [self recalculateMatrices];
    
}
- (void) recalculateMatrices {
    _viewMatrix = GLKMatrix4Multiply(
                                     GLKMatrix4MakeTranslation(_translate.x, _translate.y, _translate.z),
                                     GLKMatrix4MakeScale(_scale.x, _scale.y, _scale.z));
    
    _viewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, _viewMatrix);
}

- (GLKVector3) unproject: (CGPoint) screenPos {
    return [self unproject:screenPos z: 0.0]; // NEAR
//    return [self unProject:screenPos z: 1.0]; // FAR
}
- (GLKVector3) unproject: (CGPoint) screenPos z: (float) z {
    
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    GLKVector3 positionInWindowNear = GLKVector3Make(screenPos.x, viewport[3] - screenPos.y, z);
    
    return GLKMathUnproject(positionInWindowNear, _viewMatrix, _projectionMatrix, viewport, NULL);
}

- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3) offset attachedToObject:(CircuitObject *)object {
    
    if (object->type->numInputs == 0) return NULL;
    
    CircuitLink * closest = NULL;
    float dist = FLT_MAX;
    for(int i = 0; i < object->type->numInputs; i++) { 
        float d = GLKVector3Distance(offsetForInlet(object->type, i), offset);
        if (d < dist) {
            dist = d;
            closest = object->inputs[i];
        }
    }
    return closest;
}

- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos {
    
    __block CircuitObject *o = NULL;
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        float width = gateBackgroundHeight2.width;
        float height = gateBackgroundHeight2.height;
        GLKVector3 oPos = *(GLKVector3 *)&object->pos;
        if (pos.x > oPos.x && pos.y > oPos.y) {
            if (pos.x < oPos.x + width && pos.y < oPos.y + height) { 
                o = object;
                *stop = YES;
            }
        }
    }];
    
    return o;
}
- (CircuitObject*) findCircuitObjectAtScreenPosition: (CGPoint) screenPos {
    return [self findCircuitObjectAtPosition:[self unproject:screenPos]];
}


- (void) translate: (GLKVector3) translate {
    _translate.x += translate.x;
    _translate.y += translate.y;
    [_grid setScale:_scale translate:_translate];
    [self recalculateMatrices];
}
- (void) setScale: (float) scale {
    _scale.x = _scale.y = scale;
    [_grid setScale:_scale translate:_translate];
    [self recalculateMatrices];
}

- (float) scale {
    return _scale.x;
}

GLKVector3 offsetForOutlet(CircuitProcess *process, int index) {
    GLKVector3 res;
    res.z = 0.0;
    res.x = gateBackgroundHeight2.width - 50.0;
    if (process->numOutputs % 2 == 1) {
        res.y = 22.0 + 40.0 + index * 80.0;
    } else {
        res.y = 22.0 + index * 80.0;
    }
    return res;
}

GLKVector3 offsetForInlet(CircuitProcess *process, int index) {
    
    GLKVector3 res;
    res.x = 20.0;
    res.z = 0.0;
    if (process->numInputs % 2 == 1) {
        res.y = 22.0 + 40.0 + index * 80.0;
    } else {
        res.y = 22.0 + index * 80.0;
    }
    return res;
}

- (void) bufferSprites {
    
    __block int i = 0;
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 pos = *(GLKVector3*) &object->pos;
        BatchedSpriteInstance *instance = &_instances[i++];
        instance->x = pos.x;
        instance->y = pos.y;
        
        for(int o = 0; o < object->type->numOutputs; o++) {
            BatchedSpriteInstance *outlet = &_instances[i++];
            GLKVector3 dotPos = offsetForOutlet(object->type, o);
            outlet->x = pos.x + dotPos.x;
            outlet->y = pos.y + dotPos.y;
            BOOL isConnected = object->outputs[o] != NULL;
            if (object == _currentEditingLinkSource && o == _currentEditingLinkSourceIndex) isConnected = YES;
            outlet->tex = (object->out & 1 << o) ? (isConnected ? gateOutletActiveConnected : gateOutletActive) : (isConnected ? gateOutletInactiveConnected : gateOutletInactive);
        }
        for(int o = 0; o < object->type->numInputs; o++) {
            BatchedSpriteInstance *outlet = &_instances[i++];
            
            GLKVector3 dotPos = offsetForInlet(object->type, o);
            outlet->x = pos.x + dotPos.x;
            outlet->y = pos.y + dotPos.y;
            BOOL isConnected = object->inputs[o] != NULL;
            if (object == _currentEditingLinkTarget && o == _currentEditingLinkTargetIndex) isConnected = YES;
            outlet->tex = (object->in & 1 << o) ? (isConnected ? gateOutletActiveConnected : gateOutletActive) : (isConnected ? gateOutletInactiveConnected : gateOutletInactive);
        }
    }];
    
    _count = i;
    
    [_gateSprites buffer:_instances FromIndex:0 count:_count];
}
- (void) drawWithStack:(GLKMatrixStackRef) stack {
    
    GLKVector3 active1 = GLKVector3Make(0.1960784314, 1.0, 0.3098039216);
    GLKVector3 active2 = GLKVector3Make(0.0, 0.0, 0.0);
    
    GLKVector3 inactive1 = GLKVector3Make(1.0, 1.0, 1.0);
    GLKVector3 inactive2 = GLKVector3Make(0.2, 0.2, 0.2);
    
    _viewMatrix = GLKMatrix4Multiply(
                                     GLKMatrix4MakeTranslation(_translate.x, _translate.y, _translate.z),
                                     GLKMatrix4MakeScale(_scale.x, _scale.y, _scale.z));
    
    _viewProjectionMatrix = GLKMatrix4Multiply(_projectionMatrix, _viewMatrix);
    
    GLKMatrixStackPush(stack);
    GLKMatrixStackMultiplyMatrix4(stack, _viewMatrix);
    
    [_grid drawWithStack:stack];
    int radius = gateOutletActive.width / 2;
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        for(int sourceIndex = 0; sourceIndex < object->type->numOutputs; sourceIndex++) {
            CircuitLink *link = object->outputs[sourceIndex];
            
            while(link) {
                
                GLKVector3 dotPos = offsetForOutlet(object->type, sourceIndex);
                GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
                dotPos = offsetForInlet(link->target->type, link->targetIndex);
                GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
                bool isActive = object->out & 1 << sourceIndex;
                [bezier drawFrom:A to:B withColor1:isActive ? active1 : inactive1 color2:isActive ? active2 : inactive2  active:isActive withTransform:_viewProjectionMatrix];

                
                link = link->nextSibling;
            }
        }
                
    }];
    
    if (_currentEditingLinkSource && !_currentEditingLink) {
        CircuitObject *object = _currentEditingLinkSource;
        GLKVector3 dotPos = offsetForOutlet(object->type, _currentEditingLinkSourceIndex);
        GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
        GLKVector2 B = GLKVector2Make(_currentEditingLinkTargetPosition.x + radius, _currentEditingLinkTargetPosition.y + radius);
        bool isActive = object->out & 1 << _currentEditingLinkSourceIndex;
        [bezier drawFrom:A to:B withColor1:isActive ? active1 : inactive1 color2:isActive ? active2 : inactive2  active:isActive withTransform:_viewProjectionMatrix];
        
    }
    
    [self bufferSprites];
    
    [ShaderEffect checkError];
    
    [_gateSprites drawIndices:0 count:_count WithTransform:_viewProjectionMatrix];

    [ShaderEffect checkError];
    GLKMatrixStackPop(stack);
}
@end
