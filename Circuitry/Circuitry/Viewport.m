#import "Viewport.h"

#import "Grid.h"
#import "LinkBezier.h"
#import "SevenSegmentDisplay.h"
#import "TouchHighlight.h"
#import "Sprite.h"
#import "BatchedSprite.h"
#import "CircuitDocument.h"

@interface Viewport() {
    GLKMatrix4 _viewMatrix;
    GLKMatrix4 _viewProjectionMatrix;
    GLKMatrix4 _projectionMatrix;
    LinkBezier *bezier;
    BatchedSprite *_gateSprites;
    
    BatchedSpriteInstance *_instances;
    int _capacity;
    int _count;
    
    SevenSegmentDisplay *sevenSegment;
}
@property (nonatomic) Grid *grid;
@property (nonatomic) TouchHighlight *highlighter;
@property (nonatomic) float highlightProgress;
@property (nonatomic) float highlightOutProgress;
@property (nonatomic) GLKVector2 highlightLinkLocation;
@property (nonatomic) GLKVector2 highlightOutLinkLocation;
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
static SpriteTexturePos symbolHA;
static SpriteTexturePos symbolFA;
static SpriteTexturePos symbolPlus;
static SpriteTexturePos symbolMult;

static SpriteTexturePos letterA;
static SpriteTexturePos letterB;
static SpriteTexturePos letterC;
static SpriteTexturePos letterD;
static SpriteTexturePos letterE;
static SpriteTexturePos letterF;
static SpriteTexturePos letterS;
static SpriteTexturePos letterX;
static SpriteTexturePos letterY;
static SpriteTexturePos letterZ;
static SpriteTexturePos letterDOT;
static SpriteTexturePos letter1;
static SpriteTexturePos letter2;
static SpriteTexturePos letter3;

static SpriteTexturePos* letterTable[255];

static GLfloat radius;

- (void) dealloc {
    free(_instances);
    _instances = NULL;
}

- (id) initWithContext: (EAGLContext*) context atlas:(ImageAtlas *)atlas {
    self = [self init];
    
    _highlightProgress = 10000.0;
    _highlightOutProgress = 10000.0;
    
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
    
    radius = gateOutletActive.width / 2;
    
    gateBackgroundBottom = [atlas positionForSprite:@"gate-bottom"];
    symbolOR = [atlas positionForSprite:@"symbol-or@2x"];
    symbolNOR = [atlas positionForSprite:@"symbol-nor@2x"];
    symbolXOR = [atlas positionForSprite:@"symbol-xor@2x"];
    symbolXNOR = [atlas positionForSprite:@"symbol-xnor@2x"];
    symbolAND = [atlas positionForSprite:@"symbol-and@2x"];
    symbolNAND = [atlas positionForSprite:@"symbol-nand@2x"];
    symbolNOT = [atlas positionForSprite:@"symbol-not@2x"];
    symbolFA = [atlas positionForSprite:@"symbol-fa@2x"];
    symbolPlus = [atlas positionForSprite:@"symbol-plus@2x"];
    symbolMult = [atlas positionForSprite:@"symbol-mult@2x"];
    
    // Half adder looks exactly the same as the full adder, except without the bottom left "c".
    // As such, we can simply re-use the fa texture, but cropped a bit.
    symbolHA = [atlas positionForSprite:@"symbol-fa@2x"];
    symbolHA.theight = symbolHA.height = symbolNOT.height; // 149pt
    
    switchOn = [atlas positionForSprite:@"switch-on"];
    switchOff = [atlas positionForSprite:@"switch-off"];
    switchPressed = [atlas positionForSprite:@"switch-press"];
    
    ledOn = [atlas positionForSprite:@"led-on"];
    ledOff = [atlas positionForSprite:@"led-off"];
    
    // Letters
    ;
    letterB = [atlas positionForSprite:@"B@2x"];
    letterC = [atlas positionForSprite:@"C@2x"];
    letterD = [atlas positionForSprite:@"D@2x"];
    letterE = [atlas positionForSprite:@"E@2x"];
    letterF = [atlas positionForSprite:@"F@2x"];
    letterS = [atlas positionForSprite:@"S@2x"];
    letterX = [atlas positionForSprite:@"X@2x"];
    letterY = [atlas positionForSprite:@"Y@2x"];
    letterZ = [atlas positionForSprite:@"Z@2x"];
    letter1 = [atlas positionForSprite:@"1@2x"];
    letter2 = [atlas positionForSprite:@"2@2x"];
    letter3 = [atlas positionForSprite:@"3@2x"];
    letterDOT = [atlas positionForSprite:@"Dot@2x"];
    
    for(int i = 0; i < 256; i++) {
        letterTable[i] = NULL;
    }
    
    letterTable['A'] = &letterA;
    letterTable['B'] = &letterB;
    letterTable['C'] = &letterC;
    letterTable['D'] = &letterD;
    letterTable['E'] = &letterE;
    letterTable['F'] = &letterF;
    letterTable['S'] = &letterS;
    letterTable['X'] = &letterX;
    letterTable['Y'] = &letterY;
    letterTable['Z'] = &letterZ;
    letterTable['1'] = &letter1;
    letterTable['2'] = &letter2;
    letterTable['3'] = &letter3;
    letterTable['.'] = &letterDOT;
        
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
    
    _highlighter = [[TouchHighlight alloc] init];
    
    return self;
}
- (int) update: (NSTimeInterval) dt{
    BOOL changing = NO;
    if (_highlightProgress <= 1) {
        changing = YES;
    } else if (_highlightOutProgress <= 1) {
        changing = YES;
    }
    
    if (changing) {
        _highlightProgress += 1.5 * dt;
        _highlightOutProgress += 2.0 * dt;
        return 1;
    }
    return 0;
}

- (void) didAttachLink:(CircuitLink *)link {
    _highlightProgress = 0.0;
    GLKVector3 dotPos = offsetForInlet(link->target->type, link->targetIndex);
    GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
    _highlightLinkLocation = B;
}
- (void) didDetachEditingLink {
    _highlightProgress = 10.0;
}
- (void) didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex {
    _highlightOutProgress = 0.0;
    GLKVector3 dotPos = offsetForOutlet(object->type, outletIndex);
    GLKVector2 B = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
    _highlightOutLinkLocation = B;
}

- (void) setDocument:(CircuitDocument *)document {
    _document = document;
    self.translate = GLKVector3Make(document.circuit.viewCenterX, document.circuit.viewCenterY, 0.0);
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

- (GLKVector3) project: (GLKVector3) pos {
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    return GLKMathProject(pos, _viewMatrix, _projectionMatrix, viewport);
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
    Circuit *_circuit = self.document.circuit;
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

- (CGRect) rectForObject:(CircuitObject *) object inView:(UIView *)view {
    float scaleFactor = view.contentScaleFactor;
    
    CGSize size = sizeOfObject(object);
    
    GLKVector3 topLeft = GLKVector3Make(object->pos.x, object->pos.y, object->pos.z);
    GLKVector3 bottomRight = GLKVector3Make(object->pos.x + size.width, object->pos.y + size.height, object->pos.z);
    
    GLKVector3 pTopLeft = [self project:topLeft];
    GLKVector3 pBottomRight = [self project:bottomRight];

    return CGRectMake(pTopLeft.x / scaleFactor, view.bounds.size.height - pTopLeft.y /scaleFactor, (pBottomRight.x - pTopLeft.x) / scaleFactor, (pTopLeft.y - pBottomRight.y)/scaleFactor);
}


- (void) setTranslate:(GLKVector3)translate {
    _translate = translate;
    [_grid setScale:_scale translate:_translate];
    [self recalculateMatrices];
}
- (void) setScale:(GLKVector3)scale {
    _scale = scale;
    [_grid setScale:_scale translate:_translate];
    [self recalculateMatrices];
}

- (void) translate: (GLKVector3) translate {
    _translate.x += translate.x;
    _translate.y += translate.y;
    self.translate = _translate;
}
- (void) setScaleWithFloat: (float) scale {
    _scale.x = _scale.y = scale;
    self.scale = _scale;
}

- (float) scaleWithFloat {
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
    if (process == &CircuitProcessOr) return symbolOR;
    else if (process == &CircuitProcessNor) return symbolNOR;
    else if (process == &CircuitProcessXor) return symbolXOR;
    else if (process == &CircuitProcessXnor) return symbolXNOR;
    else if (process == &CircuitProcessAnd) return symbolAND;
    else if (process == &CircuitProcessNand) return symbolNAND;
    else if (process == &CircuitProcessNot) return symbolNOT;
    else if (process == &CircuitProcessHA) return symbolHA;
    else if (process == &CircuitProcessFA) return symbolFA;
    else if (process == &CircuitProcessAdd4) return symbolPlus;
    else if (process == &CircuitProcessAdd8) return symbolPlus;
    else if (process == &CircuitProcessMult4) return symbolMult;
    else if (process == &CircuitProcessMult8) return symbolMult;
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
    Circuit *_circuit = self.document.circuit;
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
        
        
        if (object->type == &CircuitProcessIn || object->type == &CircuitProcessButton || object->type == &CircuitProcessPushButton) {
            instance->tex = object->out ? switchOn : switchOff;
            instance->x -= 50.0;
            instance->y -= 50.0;
        } else if (object->type == &CircuitProcessLight) {
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
        
        if (object->name[0] && !object->name[1]) {
            
            char c = object->name[0];
            
            SpriteTexturePos *s = letterTable[c];

            if (s) {
                BatchedSpriteInstance *letter = &_instances[i++];
                letter->x = pos.x + 105.0;
                letter->y = pos.y + 43.0;
                letter->tex = *s;
            }
            
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
    
    [ShaderEffect checkError];
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
    
    [ShaderEffect checkError];
    [_grid drawWithStack:stack];
    
    
    
    
    [ShaderEffect checkError];
    Circuit *_circuit = self.document.circuit;
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
    
    [ShaderEffect checkError];
    [self bufferSprites];
    
    [ShaderEffect checkError];
    
    [_gateSprites drawIndices:0 count:_count WithTransform:_viewProjectionMatrix];
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        if (object->type == &CircuitProcess7Seg) {
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
    

    if (_highlightProgress <= 1.0) {
        [_highlighter drawTouchMatchingAtPosition:_highlightLinkLocation progress:_highlightProgress withTransform:_viewProjectionMatrix];
    }
    
    if (_highlightOutProgress <= 1.0) {
        [_highlighter drawOutFromPosition:_highlightOutLinkLocation progress:_highlightOutProgress withTransform:_viewProjectionMatrix];
    }

    [ShaderEffect checkError];
    GLKMatrixStackPop(stack);
}

@end
