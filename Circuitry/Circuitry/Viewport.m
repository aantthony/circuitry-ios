#import "Viewport.h"

#import "Grid.h"
#import "LinkBezier.h"
#import "SevenSegmentDisplay.h"
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
    
    Circuit *_circuit;

    BatchedSpriteInstance *_instances;
    int _capacity;
    int _count;
    
    CircuitProcess *OR  ;
    CircuitProcess *IN  ;
    CircuitProcess *OUT ;
    CircuitProcess *NOR ;
    CircuitProcess *XOR ;
    CircuitProcess *XNOR;
    CircuitProcess *AND ;
    CircuitProcess *NAND;
    CircuitProcess *NOT ;
    
    CircuitProcess *SEG7 ;
    
    SevenSegmentDisplay *sevenSegment;
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
static SpriteTexturePos switchOn;
static SpriteTexturePos switchOff;
static SpriteTexturePos switchPressed;

static SpriteTexturePos gateBackgroundTop;
static SpriteTexturePos gateBackgroundMiddle;
static SpriteTexturePos gateBackgroundBottom;

static SpriteTexturePos ledOn;
static SpriteTexturePos ledOff;

static SpriteTexturePos symbolOR;
static SpriteTexturePos symbolNOR;
static SpriteTexturePos symbolXOR;
static SpriteTexturePos symbolXNOR;
static SpriteTexturePos symbolAND;
static SpriteTexturePos symbolNAND;
static SpriteTexturePos symbolNOT;


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
    gateBackgroundTop = [atlas positionForSprite:@"gate-top"];
    gateBackgroundMiddle = [atlas positionForSprite:@"gate-middle"];
    
    gateBackgroundMiddle.v+=1;
    gateBackgroundMiddle.theight-=2;
    
    gateBackgroundBottom = [atlas positionForSprite:@"gate-bottom"];
    symbolOR = [atlas positionForSprite:@"symbol-or@2x"];
    symbolNOR = [atlas positionForSprite:@"symbol-nor@2x"];
    symbolXOR = [atlas positionForSprite:@"symbol-xor@2x"];
    symbolXNOR = [atlas positionForSprite:@"symbol-xnor@2x"];
    symbolAND = [atlas positionForSprite:@"symbol-and@2x"];
    symbolNAND = [atlas positionForSprite:@"symbol-nand@2x"];
    symbolNOT = [atlas positionForSprite:@"symbol-not@2x"];
    switchOn = [atlas positionForSprite:@"switch-on"];
    switchOff = [atlas positionForSprite:@"switch-off"];
    switchPressed = [atlas positionForSprite:@"switch-press"];
    
    
    ledOn = [atlas positionForSprite:@"led-on"];
    ledOff = [atlas positionForSprite:@"led-off"];
        
    for(int i = 0; i < _capacity; i++) {
        _instances[i].tex = gateBackgroundHeight2;
    }
    
    [ShaderEffect checkError];
    [_gateSprites buffer:_instances FromIndex:0 count:_capacity];
    
    [ShaderEffect checkError];
    bezier = [[LinkBezier alloc] init];
    [ShaderEffect checkError];
    sevenSegment = [[SevenSegmentDisplay alloc] initWithTexture: atlas.texture component:[atlas positionForSprite:@"7seg"]];
    [ShaderEffect checkError];
    return self;
}
- (int) update: (NSTimeInterval) dt{
    return 0;
}


- (void) setCircuit:(Circuit *)circuit {
    _circuit = circuit;
    IN  =[_circuit getProcessById:@"in"];
    OR  =[_circuit getProcessById:@"or"];
    NOR =[_circuit getProcessById:@"nor"];
    XOR =[_circuit getProcessById:@"xor"];
    XNOR=[_circuit getProcessById:@"xnor"];
    AND =[_circuit getProcessById:@"and"];
    NAND=[_circuit getProcessById:@"nand"];
    NOT =[_circuit getProcessById:@"not"];
    OUT =[_circuit getProcessById:@"out"];
    SEG7 =[_circuit getProcessById:@"7seg"];
}

- (Circuit *) circuit {
    return _circuit;
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

- (int) findInletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object {
    
    if (object->type->numInputs == 0) return -1;
    
    int closest = -1;
    float dist = FLT_MAX;
    for(int i = 0; i < object->type->numInputs; i++) { 
        float d = GLKVector3Distance(offsetForInlet(object->type, i), offset);
        if (d < dist) {
            dist = d;
            closest = i;
        }
    }
    return closest;
}


- (int) findOutletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object {
    
    if (object->type->numOutputs == 0) return -1;
    
    int closest = -1;
    float dist = FLT_MAX;
    for(int i = 0; i < object->type->numOutputs; i++) { 
        float d = GLKVector3Distance(offsetForOutlet(object->type, i), offset);
        if (d < dist) {
            dist = d;
            closest = i;
        }
    }
    return closest;
}



- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3) offset attachedToObject:(CircuitObject *)object {
    int index = [self findInletIndexAtOffset:offset attachedToObject:object];
    if (index == -1) return NULL;
    
    return object->inputs[index];
}

CGSize sizeOfObject(CircuitObject *object) {
    
    if (expandDrawGate(object)) {
        int middleHeight = vSpacing * 2 * MAX(object->type->numInputs, object->type->numOutputs);
        return CGSizeMake(gateBackgroundHeight2.width, gateBackgroundTop.height + middleHeight + gateBackgroundBottom.height);
    }
    return CGSizeMake(gateBackgroundHeight2.width, gateBackgroundHeight2.height);
}

- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos {
    
    __block CircuitObject *o = NULL;
    
    [_circuit enumerateObjectsInReverseUsingBlock:^(CircuitObject *object, BOOL *stop) {

        GLKVector3 oPos = *(GLKVector3 *)&object->pos;
        
        CGSize size = sizeOfObject(object);
        if (pos.x > oPos.x && pos.y > oPos.y) {
            if (pos.x < oPos.x + size.width && pos.y < oPos.y + size.height) { 
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

const float vSpacing = 33.0;

GLKVector3 offsetForOutlet(CircuitProcess *process, int index) {
    GLKVector3 res;
    res.z = 0.0;
    res.x = gateBackgroundHeight2.width - 45.0;
    if (process->numOutputs == 1) {
        res.y = 30.0 + vSpacing + index * vSpacing * 2.0;
    } else {
        res.y = 30.0 + index * vSpacing * 2.0;
    }
    return res;
}

GLKVector3 offsetForInlet(CircuitProcess *process, int index) {
    
    GLKVector3 res;
    res.x = 15.0;
    res.z = 0.0;
    if (process->numInputs == 1) {
        res.y = 30.0 + vSpacing + index * vSpacing * 2.0;
    } else {
        res.y = 30.0 + index * vSpacing * 2.0;
    }
    return res;
}

- (SpriteTexturePos) textureForProcess:(CircuitProcess *)process {
    if (process == OR) return symbolOR;
    else if (process == NOR) return symbolNOR;
    else if (process == XOR) return symbolXOR;
    else if (process == XNOR) return symbolXNOR;
    else if (process == AND) return symbolAND;
    else if (process == NAND) return symbolNAND;
    else if (process == NOT) return symbolNOT;
    else {
        SpriteTexturePos pos;
        pos.u = pos.v = pos.theight = pos.twidth = pos.width = pos.height = 0.0;
        return pos;
    };

}

BOOL expandDrawGate(CircuitObject *object) {
    if (object->type->numOutputs > 2 || object->type->numInputs > 2) {
        return YES;
    }
    return NO;
}

- (void) bufferSprites {
    
    __block int i = 0;
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 pos = *(GLKVector3*) &object->pos;
        BatchedSpriteInstance *instance = &_instances[i++];
        
        if (expandDrawGate(object)) {
            BatchedSpriteInstance *top = &_instances[i++];
            top->x = pos.x;
            top->y = pos.y;
            top->tex = gateBackgroundTop;
            
            BatchedSpriteInstance *middle = instance;
            
            instance = top;
            middle->x = pos.x;
            middle->y = pos.y + gateBackgroundTop.height - 1.0;
            middle->tex = gateBackgroundMiddle;
            middle->tex.height = vSpacing * 2 * MAX(object->type->numInputs, object->type->numOutputs) + 1.0;
            
            BatchedSpriteInstance *bottom = &_instances[i++];
            bottom->x = pos.x;
            bottom->y = middle->y + middle->tex.height - 1.0;
            bottom->tex = gateBackgroundBottom;
        } else {
            instance->x = pos.x;
            instance->y = pos.y;
            instance->tex = gateBackgroundHeight2;    
        }
        
        
        if (object->type == IN) {
            instance->tex = object->out ? switchOn : switchOff;
            instance->x -= 50.0;
            instance->y -= 50.0;
        } else if (object->type == OUT) {
            BatchedSpriteInstance *symbol = &_instances[i++];
            symbol->x = pos.x + 70.0;
            symbol->y = pos.y - 85.0;
            symbol->tex = object->in ? ledOn : ledOff;
            
        } else {            
            BatchedSpriteInstance *symbol = &_instances[i++];
            symbol->x = pos.x + 9.0;
            symbol->y = pos.y + 0.0;
            symbol->tex = [self textureForProcess:object->type];
        }
        
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
                if (link->target != link->source) {
                    GLKVector3 dotPos = offsetForOutlet(object->type, sourceIndex);
                    GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
                    dotPos = offsetForInlet(link->target->type, link->targetIndex);
                    GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
                    bool isActive = object->out & 1 << sourceIndex;
                    [bezier drawFrom:A to:B withColor1:isActive ? active1 : inactive1 color2:isActive ? active2 : inactive2  active:isActive withTransform:_viewProjectionMatrix];

                }
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
    
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        if (object->type == SEG7) {
            GLKVector3 pos = *(GLKVector3*) &object->pos;
            [sevenSegment drawAt:GLKVector3Make(pos.x + 40.0, pos.y + 40.0, 0.0) withInput:object->in withTransform:_viewProjectionMatrix];
        }
    }];
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        for(int sourceIndex = 0; sourceIndex < object->type->numOutputs; sourceIndex++) {
            CircuitLink *link = object->outputs[sourceIndex];
            
            while(link) {
                if (link->target == link->source) {
                    
                    GLKVector3 dotPos = offsetForOutlet(object->type, sourceIndex);
                    GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
                    dotPos = offsetForInlet(link->target->type, link->targetIndex);
                    GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
                    bool isActive = object->out & 1 << sourceIndex;
                    [bezier drawFrom:A to:B withColor1:isActive ? active1 : inactive1 color2:isActive ? active2 : inactive2  active:isActive withTransform:_viewProjectionMatrix];
                }
                link = link->nextSibling;
            }
        }
        
    }];
    

    [ShaderEffect checkError];
    GLKMatrixStackPop(stack);
}
@end
