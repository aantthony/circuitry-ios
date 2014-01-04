#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ShaderEffect.h"

typedef struct {
    float x, y;
    float u, v, width, height;
} BatchedSpriteInstance;

@interface BatchedSprite : NSObject

+ (void)setContext: (EAGLContext*) context;

- (id) initWithTexture:(GLKTextureInfo *)texture capacity:(int) capacity;

- (BatchedSpriteInstance *) instances;
- (void) drawWithTransform: (GLKMatrix4) viewProjectionMatrix;

@property(readonly) int capacity;
@end
