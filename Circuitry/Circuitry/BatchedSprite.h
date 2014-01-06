#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ShaderEffect.h"

typedef struct {
    float x, y;
    float u, v, width, height;
} BatchedSpriteInstance;

@interface BatchedSprite : NSObject

+ (void)setContext: (EAGLContext*) context;

// capacity * BatchedSpriteInstance worth of vram
- (id) initWithTexture:(GLKTextureInfo *)texture capacity:(int) capacity;

- (void) drawIndices:(int)start count:(int)count WithTransform: (GLKMatrix4) viewProjectionMatrix;

- (void) buffer:(const GLvoid *)data FromIndex:(int)start count:(int)count;

@end
