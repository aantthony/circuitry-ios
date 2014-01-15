#import "BatchedSprite.h"
@interface ImageAtlas : NSObject

@property(readonly) GLKTextureInfo *texture;

+ (ImageAtlas *) imageAtlasWithName:(NSString *) name;
- (id) initWithName:(NSString *) name;
- (SpriteTexturePos) positionForSprite:(NSString *) name;
@end
