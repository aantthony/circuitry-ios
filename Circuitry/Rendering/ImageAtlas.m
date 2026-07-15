//
//  ImageAtlas.m
//  Circuitry
//
//  Created by Anthony Foster on 15/01/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ImageAtlas.h"

@interface ImageAtlas() {
}
@property (nonatomic) NSDictionary *json;
@property (nonatomic) NSMutableDictionary<NSValue *, UIImage *> *spriteImages;


@end
@implementation ImageAtlas
+ (ImageAtlas *) imageAtlasWithName:(NSString *) name {
    return [[ImageAtlas alloc] initWithName:name];
}

- (id) initWithName:(NSString *) name {
    self = [super init];
    
    NSString *resourceName = [NSString stringWithFormat:@"%@-atlas", name];
    
    NSURL *atlasPng  = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"png"];
    NSURL *atlasJson = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"json"];
    
    NSInputStream *stream = [NSInputStream inputStreamWithURL:atlasJson];
    [stream open];
    
    NSError *err;
    _json = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&err];
    if (err) [[NSException exceptionWithName:err.description reason:err.localizedFailureReason userInfo:@{}] raise];

    _image = [UIImage imageWithContentsOfFile:atlasPng.path];
    if (!_image) {
        [[NSException exceptionWithName:@"ImageAtlasError" reason:@"Could not load generated atlas image." userInfo:@{}] raise];
    }
    _spriteImages = [NSMutableDictionary dictionary];
    
    
    return self;
}

- (SpriteTexturePos) positionForSprite:(NSString *)name {
    SpriteTexturePos pos;
    NSDictionary *k = _json[name];
    NSParameterAssert(k);
    pos.u = [k[@"x"] floatValue];
    pos.v = [k[@"y"] floatValue];
    pos.twidth = [k[@"width"] floatValue];
    pos.theight = [k[@"height"] floatValue];
    pos.width = pos.twidth;
    pos.height = pos.theight;
    return pos;
}

- (UIImage *) imageForSprite:(SpriteTexturePos)position {
    CGRect cropRect = CGRectMake(position.u, position.v, position.twidth, position.theight);
    NSValue *key = [NSValue valueWithCGRect:cropRect];
    UIImage *cachedImage = self.spriteImages[key];
    if (cachedImage) return cachedImage;

    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.image.CGImage, cropRect);
    if (!croppedImage) return nil;
    UIImage *image = [UIImage imageWithCGImage:croppedImage scale:self.image.scale orientation:self.image.imageOrientation];
    CGImageRelease(croppedImage);
    self.spriteImages[key] = image;
    return image;
}
@end
