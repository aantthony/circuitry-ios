#import <UIKit/UIKit.h>
#include <math.h>

#import "CircuitInternal.h"
#import "ImageAtlas.h"
@class CircuitDocument;

typedef struct {
    float x;
    float y;
} GLKVector2;

typedef struct {
    float x;
    float y;
    float z;
} GLKVector3;

typedef struct {
    float m[16];
} GLKMatrix4;

static inline GLKVector2 GLKVector2Make(float x, float y) {
    GLKVector2 vector = {x, y};
    return vector;
}

static inline GLKVector3 GLKVector3Make(float x, float y, float z) {
    GLKVector3 vector = {x, y, z};
    return vector;
}

static inline GLKVector3 GLKVector3Add(GLKVector3 left, GLKVector3 right) {
    return GLKVector3Make(left.x + right.x, left.y + right.y, left.z + right.z);
}

static inline GLKVector3 GLKVector3Subtract(GLKVector3 left, GLKVector3 right) {
    return GLKVector3Make(left.x - right.x, left.y - right.y, left.z - right.z);
}

static inline float GLKVector3Distance(GLKVector3 left, GLKVector3 right) {
    GLKVector3 delta = GLKVector3Subtract(left, right);
    return sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
}

@interface Viewport : NSObject


- (id) initWithAtlas:(ImageAtlas *)atlas;
- (int) update: (NSTimeInterval) dt;

- (void) didDetachEditingLink;
- (void) didAttachLink:(CircuitLink *)link;
- (void) didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex;

- (void) translate: (GLKVector3) translate;
- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;
- (void) drawInRect:(CGRect)rect;

- (void) setScaleWithFloat: (float) scale;
- (float) scaleWithFloat;

- (int) findOutletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (int) findInletIndexAtOffset:(GLKVector3) offset attachedToObject:(CircuitObject *)object;
- (CircuitLink *) findCircuitLinkAtOffset: (GLKVector3)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject*) findCircuitObjectAtPosition: (GLKVector3) pos;
- (CircuitObject*) findCircuitObjectNearPosition: (GLKVector3) pos;
- (CGRect) rectForObject:(CircuitObject *) object inView:(UIView *)view;

- (GLKVector3) unproject: (CGPoint) screenPos;

@property (nonatomic) CircuitDocument *document;
@property (nonatomic) CircuitLink *currentEditingLink;
@property (nonatomic) CircuitObject *currentEditingLinkSource;
@property (nonatomic) CircuitObject *currentEditingLinkTarget;
@property (nonatomic) int currentEditingLinkSourceIndex;
@property (nonatomic) int currentEditingLinkTargetIndex;
@property (nonatomic) GLKVector3 currentEditingLinkTargetPosition;

@property (nonatomic) GLKVector3 translate;
@property (nonatomic) GLKVector3 scale;

@end
