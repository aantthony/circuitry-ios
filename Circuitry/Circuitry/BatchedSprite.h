#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "ShaderEffect.h"

typedef struct {
    GLushort x, y;
    GLubyte u, v;
    GLubyte width, height;
} BatchedSpriteInstance;

@interface BatchedSprite : NSObject

- (id) initWithCapacity:(int) capacity;
- (BatchedSpriteInstance *) instances;
@property(readonly) int capacity;
- (void) flush;

@end
