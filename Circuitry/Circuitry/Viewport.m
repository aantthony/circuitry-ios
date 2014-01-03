#import "Viewport.h"

#import "Grid.h"
#import "Sprite.h"

@interface Viewport() {
    GLKMatrix4 _viewMatrix;
    GLKMatrix4 _viewProjectionMatrix;
    GLKMatrix4 _projectionMatrix;
    GLKVector3 _translate;
    GLKVector3 _scale;
}
@property Grid *grid;
@end

@implementation Viewport

Sprite *gateAND;

- (id) initWithContext: (EAGLContext*) context {
    self = [self init];
        
    _translate = GLKVector3Make(0.0, 0.0, 0.0);
    _scale     = GLKVector3Make(1.0, 1.0, 1.0);
    
    _grid = [[Grid alloc] init];
    
    [_grid setScale:_scale translate:_translate];
    
    [self recalculateMatrices];
    
    [Sprite setContext: context];
    
    gateAND = [[Sprite alloc] initWithTexture:[Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gate-test" ofType:@"png"]]];
    
    return self;
}
- (void)update {
    [_circuit simulate: 1];
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

- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos {
    
    __block CircuitObject *o = NULL;
    
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        float width = 204.0;
        float height = 100.0;
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

- (void) draw {
    
    _grid.viewProjectionMatrix = _viewProjectionMatrix;
    [_grid draw];

    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 pos = *(GLKVector3*) &object->pos;
        [gateAND drawAtPoint:pos withTransform: _viewProjectionMatrix];
    }];
}
@end
