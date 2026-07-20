#import <UIKit/UIKit.h>
#include <math.h>

#import "CircuitInternal.h"
#import "ImageAtlas.h"
@class CircuitDocument;
@class CircuitNote;
@class SKScene;

@interface Viewport : NSObject


- (id) initWithAtlas:(ImageAtlas *)atlas;
- (int) update: (NSTimeInterval) dt;

- (void) didDetachEditingLink;
- (void) didAttachLink:(CircuitLink *)link;
- (void) didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex;

- (void)translateBy:(CGVector)translation;

// SpriteKit-backed editor rendering.
- (void) attachToScene:(SKScene *)scene backgroundImage:(UIImage *)backgroundImage;
- (void) setSceneContentNeedsUpdate;
- (void) updateSceneForViewSize:(CGSize)viewSize allowContentRebuild:(BOOL)allowContentRebuild;

- (int)findOutletIndexAtOffset:(CGVector)offset attachedToObject:(CircuitObject *)object;
- (int)findInletIndexAtOffset:(CGVector)offset attachedToObject:(CircuitObject *)object;
- (CircuitLink *)findCircuitLinkAtOffset:(CGVector)offset attachedToObject:(CircuitObject *)object;
- (CircuitObject *)findCircuitObjectAtPosition:(CGPoint)position;
- (CircuitObject *)findCircuitObjectNearPosition:(CGPoint)position;
- (BOOL)isPosition:(CGPoint)position onMomentaryButtonCap:(CircuitObject *)object;
- (CircuitNote *)findNoteAtPosition:(CGPoint)position;
- (CircuitNote *)findNoteResizeHandleAtPosition:(CGPoint)position;
- (CGRect) resizeHandleRectForNote:(CircuitNote *)note;
- (CGRect) rectForObject:(CircuitObject *) object inView:(UIView *)view;
- (CGRect) rectForNote:(CircuitNote *)note inView:(UIView *)view;

- (CGPoint)unproject:(CGPoint)screenPosition;

@property (nonatomic) CircuitDocument *document;
@property (nonatomic) CircuitLink *currentEditingLink;
@property (nonatomic) CircuitObject *currentEditingLinkSource;
@property (nonatomic) CircuitObject *currentEditingLinkTarget;
@property (nonatomic) int currentEditingLinkSourceIndex;
@property (nonatomic) int currentEditingLinkTargetIndex;
@property (nonatomic) CGPoint currentEditingLinkTargetPosition;

@property (nonatomic) CGPoint translation;
@property (nonatomic) CGFloat zoomScale;

@end
