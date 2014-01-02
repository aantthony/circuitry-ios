#import "Viewport.h"

@interface Viewport()
@property Grid *grid;
@end

@implementation Viewport

Sprite *bg, *bgTest;

- (id) initWithContext: (EAGLContext*) context {
    if (self = [super init]) {
        _grid = [[Grid alloc] init];
        
        
        [Sprite setContext: context];
        
        GLKTextureInfo *texture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"testbg" ofType:@"png"]];
        
        GLKTextureInfo *bgTexture = [Sprite textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"]];
        
        bgTest = [[Sprite alloc] initWithTexture:texture];
        bg = [[Sprite alloc] initWithTexture:bgTexture];
           
    }
    return self;
}
- (void)update {
    [_circuit simulate: 1];
}
- (void) draw {
//    [bgTest drawAtPoint: GLKVector3Make(0.0, 0.0, 0.0) withTransform: _modelViewProjectionMatrix];
    [bg drawAtPoint: GLKVector3Make(0.0, 0.0, 0.0) withTransform: _modelViewProjectionMatrix];
    _grid.modelViewProjectionMatrix = _modelViewProjectionMatrix;
    [_grid draw];
}
@end
