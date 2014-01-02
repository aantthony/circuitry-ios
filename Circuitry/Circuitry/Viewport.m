#import "Viewport.h"

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

Sprite *bg, *bgTest;
Sprite *gateAND;

- (id) initWithContext: (EAGLContext*) context {
    self = [self init];
        
    _translate = GLKVector3Make(0.0, 0.0, 0.0);
    _scale     = GLKVector3Make(1.0, 1.0, 1.0);
    
    _grid = [[Grid alloc] init];
    
    [_grid setScale:_scale translate:_translate];
    
    [self recalculateMatrices];
    
    [Sprite setContext: context];
    
    GLKTextureInfo *texture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"testbg" ofType:@"png"]];
    
    GLKTextureInfo *bgTexture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"]];
    
    bgTest = [[Sprite alloc] initWithTexture:texture];
    bg = [[Sprite alloc] initWithTexture:bgTexture];
       
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
    NSLog(@"get scale");
    return _scale.x;
}

- (void) draw {
    [bg drawWithTransform: _projectionMatrix];
    _grid.viewProjectionMatrix = _viewProjectionMatrix;
    [_grid draw];

    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 pos = *(GLKVector3*) &object->pos;
        [gateAND drawAtPoint:pos withTransform: _viewProjectionMatrix];
    }];
}
@end
