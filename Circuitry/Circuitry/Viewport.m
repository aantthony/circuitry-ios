#import "Viewport.h"

@interface Viewport()
@property Grid *grid;
@end

@implementation Viewport

Sprite *bg, *bgTest;
Sprite *gateAND;

- (id) initWithContext: (EAGLContext*) context {
    if (self = [super init]) {
        _grid = [[Grid alloc] init];
        
        
        [Sprite setContext: context];
        
        GLKTextureInfo *texture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"testbg" ofType:@"png"]];
        
        GLKTextureInfo *bgTexture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"]];
        
        bgTest = [[Sprite alloc] initWithTexture:texture];
        bg = [[Sprite alloc] initWithTexture:bgTexture];
           
        gateAND = [[Sprite alloc] initWithTexture:[Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gate-test" ofType:@"png"]]];
                   
    }
    return self;
}
- (void)update {
    [_circuit simulate: 1];
}
- (void) draw {
//    [bgTest drawAtPoint: GLKVector3Make(0.0, 0.0, 0.0) withTransform: _modelViewProjectionMatrix];
    [bg drawWithTransform:_modelViewProjectionMatrix];
    _grid.modelViewProjectionMatrix = _modelViewProjectionMatrix;
    [_grid draw];

    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 pos = *(GLKVector3*) &object->pos;
        [gateAND drawAtPoint:pos withTransform:_modelViewProjectionMatrix];
    }];
}
@end
