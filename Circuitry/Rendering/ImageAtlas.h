#import <UIKit/UIKit.h>

typedef struct {
    CGFloat u;
    CGFloat v;
    CGFloat twidth;
    CGFloat theight;
    CGFloat width;
    CGFloat height;
} SpriteTexturePos;

@interface ImageAtlas : NSObject

@property(nonatomic, readonly) UIImage *image;

+ (ImageAtlas *) imageAtlasWithName:(NSString *) name;
- (id) initWithName:(NSString *) name;
- (SpriteTexturePos) positionForSprite:(NSString *) name;
- (UIImage *) imageForSprite:(SpriteTexturePos) position;
@end
