#import "BatchedSprite.h"
@interface ImageAtlas : NSObject

@property(nonatomic, readonly) GLKTextureInfo *texture;

+ (ImageAtlas *) imageAtlasWithName:(NSString *) name;
- (id) initWithName:(NSString *) name;
- (SpriteTexturePos) positionForSprite:(NSString *) name;
@end
