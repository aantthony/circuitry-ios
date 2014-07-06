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

    NSError* error = nil;
    
    int mipmap_levels = 0;
    
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool: mipmap_levels > 0], GLKTextureLoaderGenerateMipmaps,
                             [NSNumber numberWithBool:NO], GLKTextureLoaderApplyPremultiplication,
                             nil
                             ];
    
    _texture = [GLKTextureLoader textureWithContentsOfURL:atlasPng options:options error: &error];
    
    if (error) {
        [[NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:@{}] raise];
    }
    
    
    return self;
}

- (SpriteTexturePos) positionForSprite:(NSString *)name {
    SpriteTexturePos pos;
    pos.u = [_json[name][@"x"] floatValue];
    pos.v = [_json[name][@"y"] floatValue];
    pos.twidth = [_json[name][@"width"] floatValue];
    pos.theight = [_json[name][@"height"] floatValue];
    pos.width = pos.twidth;
    pos.height = pos.theight;
    return pos;
}
@end
