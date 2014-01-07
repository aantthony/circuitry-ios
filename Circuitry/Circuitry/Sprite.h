#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Sprite : NSObject

+ (void)setContext: (EAGLContext*) context;

+ (GLKTextureInfo *) textureWithContentsOfURL: (NSURL *) url;

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture atX: (int) x Y:(int) y width:(int)w height: (int) h;

- (Sprite *) initWithTexture: (GLKTextureInfo *) texture;


- (void) drawAtPoint: (GLKVector3) pos withSize: (GLKVector2) size withTransform:(GLKMatrix4) modelViewProjectionMatrix;

- (void) drawWithSize: (GLKVector2) size withTransform:(GLKMatrix4) modelViewProjectionMatrix;
- (void) drawAtPoint: (GLKVector3) pos withTransform:(GLKMatrix4) modelViewProjectionMatrix;
- (void) drawWithTransform: (GLKMatrix4) modelViewProjectionMatrix;

@end
