#import "Viewport.h"
#import <CoreImage/CoreImage.h>
#import <SpriteKit/SpriteKit.h>

#import "CircuitDocument.h"

@interface Viewport()
@property (nonatomic) ImageAtlas *atlas;
@property (nonatomic) float highlightProgress;
@property (nonatomic) float highlightOutProgress;
@property (nonatomic) GLKVector2 highlightLinkLocation;
@property (nonatomic) GLKVector2 highlightOutLinkLocation;
@property (nonatomic, weak) SKScene *scene;
@property (nonatomic) SKSpriteNode *sceneBackground;
@property (nonatomic) SKShapeNode *sceneGrid;
@property (nonatomic) SKNode *sceneWorld;
@property (nonatomic) NSMutableDictionary<NSValue *, SKTexture *> *sceneTextures;
@property (nonatomic) UIImage *ledOnGreenImage;
@property (nonatomic) UIImage *ledOnRedImage;
@property (nonatomic) UIImage *ledOnBlueImage;
@property (nonatomic) SKTexture *ledOnGreenTexture;
@property (nonatomic) SKTexture *ledOnRedTexture;
@property (nonatomic) SKTexture *ledOnBlueTexture;
@property (nonatomic) BOOL sceneContentNeedsUpdate;
@end

@implementation Viewport

static SpriteTexturePos gateBackgroundHeight1;
static SpriteTexturePos gateBackgroundHeight2;
static SpriteTexturePos gateOutletInactive;
static SpriteTexturePos gateOutletActive;
static SpriteTexturePos gateOutletActiveConnected;
static SpriteTexturePos gateOutletInactiveConnected;
static SpriteTexturePos switchOn;
static SpriteTexturePos switchOff;

static SpriteTexturePos gateBackgroundTop;
static SpriteTexturePos gateBackgroundMiddle;
static SpriteTexturePos gateBackgroundBottom;

static SpriteTexturePos ledOnGreen;
static SpriteTexturePos ledOnWhite;
static SpriteTexturePos ledOff;
static SpriteTexturePos sevenSegment;

static SpriteTexturePos symbolOR;
static SpriteTexturePos symbolNOR;
static SpriteTexturePos symbolXOR;
static SpriteTexturePos symbolXNOR;
static SpriteTexturePos symbolAND;
static SpriteTexturePos symbolJK;
static SpriteTexturePos symbolSR;
static SpriteTexturePos symbolSER;
static SpriteTexturePos symbolT;
static SpriteTexturePos symbolD;
static SpriteTexturePos symbolCLKIN;
static SpriteTexturePos symbolNAND;
static SpriteTexturePos symbolNOT;
static SpriteTexturePos symbolHA;
static SpriteTexturePos symbolFA;
static SpriteTexturePos symbolPlus;
static SpriteTexturePos symbolMult;

static SpriteTexturePos letterA;
static SpriteTexturePos letterB;
static SpriteTexturePos letterC;
static SpriteTexturePos letterD;
static SpriteTexturePos letterE;
static SpriteTexturePos letterF;
static SpriteTexturePos letterR;
static SpriteTexturePos letterS;
static SpriteTexturePos letterQ;
static SpriteTexturePos letterX;
static SpriteTexturePos letterY;
static SpriteTexturePos letterZ;
static SpriteTexturePos letterDOT;
static SpriteTexturePos letter1;
static SpriteTexturePos letter2;
static SpriteTexturePos letter3;
static SpriteTexturePos letter4;

static SpriteTexturePos* letterTable[256];
static CGFloat radius;
static const CGFloat vSpacing = 33.0;

static UIImage *LEDImageByShiftingHue(UIImage *source, CGFloat angle, CGFloat saturation, CGFloat brightness, CGFloat contrast) {
    CIImage *input = source.CIImage ?: [CIImage imageWithCGImage:source.CGImage];
    if (!input) return source;

    CIFilter *hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
    [hueFilter setValue:input forKey:kCIInputImageKey];
    [hueFilter setValue:@(angle) forKey:kCIInputAngleKey];

    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setValue:hueFilter.outputImage forKey:kCIInputImageKey];
    [colorFilter setValue:@(saturation) forKey:kCIInputSaturationKey];
    [colorFilter setValue:@(brightness) forKey:kCIInputBrightnessKey];
    [colorFilter setValue:@(contrast) forKey:kCIInputContrastKey];
    CIImage *output = colorFilter.outputImage;
    if (!output) return source;

    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [context createCGImage:output fromRect:input.extent];
    if (!imageRef) return source;
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:source.scale orientation:source.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

- (id)initWithAtlas:(ImageAtlas *)atlas {
    self = [super init];
    if (!self) return nil;

    _atlas = atlas;
    _highlightProgress = 10000.0;
    _highlightOutProgress = 10000.0;
    _sceneTextures = [NSMutableDictionary dictionary];
    _sceneContentNeedsUpdate = YES;

    CGFloat initialScale = 0.5;
    _translate = GLKVector3Make(0.0, 0.0, 0.0);
    _scale = GLKVector3Make(initialScale, initialScale, initialScale);

    gateBackgroundHeight1 = [atlas positionForSprite:@"single@2x"];
    gateBackgroundHeight2 = [atlas positionForSprite:@"double@2x"];
    gateOutletInactive = [atlas positionForSprite:@"inactive@2x"];
    gateOutletActive = [atlas positionForSprite:@"active@2x"];
    gateOutletActiveConnected = [atlas positionForSprite:@"activeconnected@2x"];
    gateOutletInactiveConnected = [atlas positionForSprite:@"inactiveconnected@2x"];
    gateBackgroundTop = [atlas positionForSprite:@"gate-top"];
    gateBackgroundMiddle = [atlas positionForSprite:@"gate-middle"];
    gateBackgroundMiddle.v += 1;
    gateBackgroundMiddle.theight -= 2;

    radius = gateOutletActive.width / 2;

    gateBackgroundBottom = [atlas positionForSprite:@"gate-bottom"];
    symbolOR = [atlas positionForSprite:@"symbol-or@2x"];
    symbolNOR = [atlas positionForSprite:@"symbol-nor@2x"];
    symbolXOR = [atlas positionForSprite:@"symbol-xor@2x"];
    symbolXNOR = [atlas positionForSprite:@"symbol-xnor@2x"];
    symbolAND = [atlas positionForSprite:@"symbol-and@2x"];
    symbolJK = [atlas positionForSprite:@"symbol-jk@2x"];
    symbolSR = [atlas positionForSprite:@"symbol-sr@2x"];
    symbolSER = [atlas positionForSprite:@"symbol-ser@2x"];
    symbolT = [atlas positionForSprite:@"symbol-t@2x"];
    symbolD = [atlas positionForSprite:@"symbol-d@2x"];
    symbolCLKIN = [atlas positionForSprite:@"symbol-clkin@2x"];
    symbolNAND = [atlas positionForSprite:@"symbol-nand@2x"];
    symbolNOT = [atlas positionForSprite:@"symbol-not@2x"];
    symbolFA = [atlas positionForSprite:@"symbol-fa@2x"];
    symbolPlus = [atlas positionForSprite:@"symbol-plus@2x"];
    symbolMult = [atlas positionForSprite:@"symbol-mult@2x"];

    symbolHA = [atlas positionForSprite:@"symbol-fa@2x"];
    symbolHA.theight = symbolHA.height = symbolNOT.height;

    switchOn = [atlas positionForSprite:@"switch-on"];
    switchOff = [atlas positionForSprite:@"switch-off"];

    ledOnGreen = [atlas positionForSprite:@"led-on-green"];
    ledOnWhite = [atlas positionForSprite:@"led-on"];
    ledOff = [atlas positionForSprite:@"led-off"];
    UIImage *greenLED = [atlas imageForSprite:ledOnGreen];
    _ledOnGreenImage = LEDImageByShiftingHue(greenLED, 0.0, 1.35, -0.01, 1.04);
    _ledOnRedImage = LEDImageByShiftingHue(greenLED, -(2.0 * M_PI / 3.0), 2.15, -0.03, 1.10);
    _ledOnBlueImage = LEDImageByShiftingHue(greenLED, 2.0 * M_PI / 3.0, 2.15, -0.03, 1.10);
    sevenSegment = [atlas positionForSprite:@"7seg"];

    letterA = [atlas positionForSprite:@"A@2x"];
    letterB = [atlas positionForSprite:@"B@2x"];
    letterC = [atlas positionForSprite:@"C@2x"];
    letterD = [atlas positionForSprite:@"D@2x"];
    letterE = [atlas positionForSprite:@"E@2x"];
    letterF = [atlas positionForSprite:@"F@2x"];
    letterR = [atlas positionForSprite:@"R@2x"];
    letterS = [atlas positionForSprite:@"S@2x"];
    letterQ = [atlas positionForSprite:@"Q@2x"];
    letterX = [atlas positionForSprite:@"X@2x"];
    letterY = [atlas positionForSprite:@"Y@2x"];
    letterZ = [atlas positionForSprite:@"Z@2x"];
    letter1 = [atlas positionForSprite:@"1@2x"];
    letter2 = [atlas positionForSprite:@"2@2x"];
    letter3 = [atlas positionForSprite:@"3@2x"];
    letter4 = [atlas positionForSprite:@"4@2x"];
    letterDOT = [atlas positionForSprite:@"Dot@2x"];

    for(int i = 0; i <= 0xff; i++) {
        letterTable[i] = NULL;
    }
    letterTable['A'] = &letterA;
    letterTable['B'] = &letterB;
    letterTable['C'] = &letterC;
    letterTable['D'] = &letterD;
    letterTable['E'] = &letterE;
    letterTable['F'] = &letterF;
    letterTable['R'] = &letterR;
    letterTable['S'] = &letterS;
    letterTable['Q'] = &letterQ;
    letterTable['X'] = &letterX;
    letterTable['Y'] = &letterY;
    letterTable['Z'] = &letterZ;
    letterTable['1'] = &letter1;
    letterTable['2'] = &letter2;
    letterTable['3'] = &letter3;
    letterTable['4'] = &letter4;
    letterTable['.'] = &letterDOT;

    return self;
}

- (int)update:(NSTimeInterval)dt {
    BOOL changing = _highlightProgress <= 1 || _highlightOutProgress <= 1;
    if (changing) {
        _highlightProgress += 1.5 * dt;
        _highlightOutProgress += 2.0 * dt;
        return 1;
    }
    return 0;
}

static GLKVector3 offsetForOutlet(CircuitProcess *process, int index) {
    GLKVector3 res;
    res.z = 0.0;
    res.x = gateBackgroundHeight2.width - 45.0;
    if (process->numOutputs == 1) {
        res.y = 30.0 + vSpacing + index * vSpacing * 2.0;
    } else {
        res.y = 30.0 + index * vSpacing * 2.0;
    }
    return res;
}

static GLKVector3 offsetForInlet(CircuitProcess *process, int index) {
    GLKVector3 res;
    res.x = 15.0;
    res.z = 0.0;
    if (process->numInputs == 1) {
        res.y = 30.0 + vSpacing + index * vSpacing * 2.0;
    } else {
        res.y = 30.0 + index * vSpacing * 2.0;
    }
    return res;
}

- (void)didAttachLink:(CircuitLink *)link {
    _highlightProgress = 0.0;
    GLKVector3 dotPos = offsetForInlet(link->target->type, link->targetIndex);
    _highlightLinkLocation = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
}

- (void)didDetachEditingLink {
    _highlightProgress = 10.0;
}

- (void)didBeginCreatingLink:(CircuitObject *)object outletIndex:(int)outletIndex {
    _highlightOutProgress = 0.0;
    GLKVector3 dotPos = offsetForOutlet(object->type, outletIndex);
    _highlightOutLinkLocation = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
}

- (void)setDocument:(CircuitDocument *)document {
    _document = document;
    self.translate = GLKVector3Make(document.circuit.viewCenterX, document.circuit.viewCenterY, 0.0);
    self.sceneContentNeedsUpdate = YES;
}

- (void)setProjectionMatrix:(GLKMatrix4)projectionMatrix {
}

- (GLKVector3)project:(GLKVector3)pos {
    return GLKVector3Make(pos.x * _scale.x + _translate.x, pos.y * _scale.y + _translate.y, pos.z);
}

- (GLKVector3)unproject:(CGPoint)screenPos {
    return GLKVector3Make((screenPos.x - _translate.x) / _scale.x, (screenPos.y - _translate.y) / _scale.y, 0.0);
}

- (int)findInletIndexAtOffset:(GLKVector3)offset attachedToObject:(CircuitObject *)object {
    if (object->type->numInputs == 0) return -1;

    int closest = -1;
    float dist = FLT_MAX;
    for(int i = 0; i < object->type->numInputs; i++) {
        float d = GLKVector3Distance(offsetForInlet(object->type, i), offset);
        if (d < dist) {
            dist = d;
            closest = i;
        }
    }
    return closest;
}

- (int)findOutletIndexAtOffset:(GLKVector3)offset attachedToObject:(CircuitObject *)object {
    if (object->type->numOutputs == 0) return -1;

    int closest = -1;
    float dist = FLT_MAX;
    for(int i = 0; i < object->type->numOutputs; i++) {
        float d = GLKVector3Distance(offsetForOutlet(object->type, i), offset);
        if (d < dist) {
            dist = d;
            closest = i;
        }
    }
    return closest;
}

- (CircuitLink *)findCircuitLinkAtOffset:(GLKVector3)offset attachedToObject:(CircuitObject *)object {
    int index = [self findInletIndexAtOffset:offset attachedToObject:object];
    if (index == -1) return NULL;
    return object->inputs[index];
}

static BOOL expandDrawGate(CircuitObject *object) {
    return object->type->numOutputs > 2 || object->type->numInputs > 2;
}

static CGSize sizeOfObject(CircuitObject *object) {
    if (expandDrawGate(object)) {
        int middleHeight = vSpacing * 2 * MAX(object->type->numInputs, object->type->numOutputs);
        return CGSizeMake(gateBackgroundHeight2.width, gateBackgroundTop.height + middleHeight + gateBackgroundBottom.height);
    }
    return CGSizeMake(gateBackgroundHeight2.width, gateBackgroundHeight2.height);
}

static CGRect momentaryButtonCapRect(CircuitObject *object) {
    CGSize objectSize = sizeOfObject(object);
    static const CGFloat hitDiameter = 132.0;
    static const CGFloat trailingTerminalArea = 70.0;
    static const CGFloat verticalOpticalOffset = -6.0;
    CGFloat usableWidth = objectSize.width - trailingTerminalArea;
    return CGRectMake(object->pos.x + (usableWidth - hitDiameter) * 0.5,
                      object->pos.y + (objectSize.height - hitDiameter) * 0.5 + verticalOpticalOffset,
                      hitDiameter,
                      hitDiameter);
}

- (CircuitObject*)findCircuitObjectAtPosition:(GLKVector3)pos {
    __block CircuitObject *o = NULL;
    Circuit *_circuit = self.document.circuit;
    [_circuit enumerateObjectsInReverseUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 oPos = *(GLKVector3 *)&object->pos;
        CGSize size = sizeOfObject(object);
        if (pos.x > oPos.x && pos.y > oPos.y && pos.x < oPos.x + size.width && pos.y < oPos.y + size.height) {
            o = object;
            *stop = YES;
        }
    }];
    return o;
}

- (BOOL)isPosition:(GLKVector3)position onMomentaryButtonCap:(CircuitObject *)object {
    if (!object || object->type != &CircuitProcessPushButton) return NO;
    CGRect rect = momentaryButtonCapRect(object);
    CGFloat dx = (position.x - CGRectGetMidX(rect)) / (CGRectGetWidth(rect) * 0.5);
    CGFloat dy = (position.y - CGRectGetMidY(rect)) / (CGRectGetHeight(rect) * 0.5);
    return dx * dx + dy * dy <= 1.0;
}

- (CircuitObject*)findCircuitObjectNearPosition:(GLKVector3)pos {
    CircuitObject *a = [self findCircuitObjectAtPosition:pos];
    if (a) return a;

    __block CircuitObject *o = NULL;
    float v = 60;
    Circuit *_circuit = self.document.circuit;
    [_circuit enumerateObjectsInReverseUsingBlock:^(CircuitObject *object, BOOL *stop) {
        GLKVector3 oPos = *(GLKVector3 *)&object->pos;
        CGSize size = sizeOfObject(object);
        if (pos.x + v > oPos.x && pos.y + v > oPos.y && pos.x - v < oPos.x + size.width && pos.y - v < oPos.y + size.height) {
            o = object;
            *stop = YES;
        }
    }];
    return o;
}

- (CircuitNote *)findNoteAtPosition:(GLKVector3)pos {
    for (CircuitNote *note in self.document.circuit.notes.reverseObjectEnumerator) {
        if (CGRectContainsPoint(note.frame, CGPointMake(pos.x, pos.y))) {
            return note;
        }
    }
    return nil;
}

- (CGRect)resizeHandleRectForNote:(CircuitNote *)note {
    // Keep the interactive target a comfortable, predictable size on screen,
    // regardless of the current canvas zoom.
    CGFloat worldSize = 56.0 / MAX(_scale.x, 0.001);
    worldSize = MIN(worldSize, MIN(note.frame.size.width, note.frame.size.height));
    return CGRectMake(CGRectGetMaxX(note.frame) - worldSize,
                      CGRectGetMaxY(note.frame) - worldSize,
                      worldSize, worldSize);
}

- (CircuitNote *)findNoteResizeHandleAtPosition:(GLKVector3)pos {
    CGPoint point = CGPointMake(pos.x, pos.y);
    for (CircuitNote *note in self.document.circuit.notes.reverseObjectEnumerator) {
        if (CGRectContainsPoint([self resizeHandleRectForNote:note], point)) {
            return note;
        }
    }
    return nil;
}

- (CGRect)rectForObject:(CircuitObject *)object inView:(UIView *)view {
    CGSize size = sizeOfObject(object);
    CGPoint origin = [self screenPointForWorldPoint:CGPointMake(object->pos.x, object->pos.y)];
    return CGRectMake(origin.x, origin.y, size.width * _scale.x, size.height * _scale.y);
}

- (CGRect)rectForNote:(CircuitNote *)note inView:(UIView *)view {
    return [self screenRectForWorldRect:note.frame];
}

- (void)setTranslate:(GLKVector3)translate {
    _translate = translate;
}

- (void)setScale:(GLKVector3)scale {
    _scale = scale;
}

- (void)translate:(GLKVector3)translate {
    _translate.x += translate.x;
    _translate.y += translate.y;
    self.translate = _translate;
}

- (void)setScaleWithFloat:(float)scale {
    _scale.x = _scale.y = scale;
    self.scale = _scale;
}

- (float)scaleWithFloat {
    return _scale.x;
}

- (SpriteTexturePos)textureForProcess:(CircuitProcess *)process {
    if (process == &CircuitProcessOr) return symbolOR;
    else if (process == &CircuitProcessNor) return symbolNOR;
    else if (process == &CircuitProcessXor) return symbolXOR;
    else if (process == &CircuitProcessXnor) return symbolXNOR;
    else if (process == &CircuitProcessAnd) return symbolAND;
    else if (process == &CircuitProcessJK) return symbolJK;
    else if (process == &CircuitProcessSR) return symbolSR;
    else if (process == &CircuitProcessSER) return symbolSER;
    else if (process == &CircuitProcessT) return symbolT;
    else if (process == &CircuitProcessD) return symbolD;
    else if (process == &CircuitProcessNand) return symbolNAND;
    else if (process == &CircuitProcessNot) return symbolNOT;
    else if (process == &CircuitProcessHA) return symbolHA;
    else if (process == &CircuitProcessFA) return symbolFA;
    else if (process == &CircuitProcessAdd4) return symbolPlus;
    else if (process == &CircuitProcessAdd8) return symbolPlus;
    else if (process == &CircuitProcessMult4) return symbolMult;
    else if (process == &CircuitProcessMult8) return symbolMult;
    else if (process == &CircuitProcessD4) return symbolCLKIN;
    else if (process == &CircuitProcessD8) return symbolCLKIN;
    else if (process == &CircuitProcessD16) return symbolCLKIN;
    else if (process == &CircuitProcessClock) return symbolCLKIN;
    else if (process == &CircuitProcessSlowClock) return symbolCLKIN;

    SpriteTexturePos pos;
    pos.u = pos.v = pos.theight = pos.twidth = pos.width = pos.height = 0.0;
    return pos;
}

- (CGPoint)screenPointForWorldPoint:(CGPoint)point {
    return CGPointMake(point.x * _scale.x + _translate.x, point.y * _scale.y + _translate.y);
}

- (CGRect)screenRectForWorldRect:(CGRect)rect {
    CGPoint origin = [self screenPointForWorldPoint:rect.origin];
    return CGRectMake(origin.x, origin.y, rect.size.width * _scale.x, rect.size.height * _scale.y);
}

#pragma mark - SpriteKit rendering

- (SKTexture *)sceneTextureForSprite:(SpriteTexturePos)position {
    CGRect cropRect = CGRectMake(position.u, position.v, position.twidth, position.theight);
    NSValue *key = [NSValue valueWithCGRect:cropRect];
    SKTexture *texture = self.sceneTextures[key];
    if (!texture) {
        UIImage *image = [self.atlas imageForSprite:position];
        if (!image) return nil;
        texture = [SKTexture textureWithImage:image];
        texture.filteringMode = SKTextureFilteringLinear;
        self.sceneTextures[key] = texture;
    }
    return texture;
}

- (void)addSceneSprite:(SpriteTexturePos)texturePosition atWorldPoint:(CGPoint)point {
    SKTexture *texture = [self sceneTextureForSprite:texturePosition];
    if (!texture) return;
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:texture];
    sprite.size = CGSizeMake(texturePosition.width, texturePosition.height);
    sprite.position = CGPointMake(point.x + texturePosition.width * 0.5,
                                  point.y + texturePosition.height * 0.5);
    // sceneWorld flips UIKit's downward Y axis; flip bitmap content back.
    sprite.yScale = -1.0;
    // Preserve painter's-order semantics from the old Core Graphics renderer.
    // Links occupy z=0...2; gate parts are layered in insertion order above them.
    sprite.zPosition = 100.0 + self.sceneWorld.children.count * 0.001;
    [self.sceneWorld addChild:sprite];
}

- (void)addSceneLinkFrom:(GLKVector2)A to:(GLKVector2)B active:(BOOL)isActive {
    CGFloat dx = (B.x - A.x) * 0.5;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, A.x, A.y);
    CGPathAddCurveToPoint(path, NULL, A.x + dx, A.y, B.x - dx, B.y, B.x, B.y);

    CGFloat width = MAX(7.0 / MAX(_scale.x, 0.001), 16.0);
    NSArray<UIColor *> *colors = isActive
        ? @[[UIColor colorWithRed:0.0 green:0.22 blue:0.03 alpha:1.0],
            [UIColor colorWithRed:0.0 green:0.72 blue:0.09 alpha:1.0],
            [UIColor colorWithRed:0.48 green:1.0 blue:0.53 alpha:1.0]]
        : @[[UIColor colorWithWhite:0.08 alpha:1.0],
            [UIColor colorWithWhite:0.68 alpha:1.0],
            [UIColor colorWithWhite:0.9 alpha:1.0]];
    CGFloat widths[] = { width, MAX(1.0, width - 2.0), MAX(2.0 / MAX(_scale.x, 0.001), width * 0.38) };
    for (NSUInteger index = 0; index < colors.count; index++) {
        SKShapeNode *line = [SKShapeNode shapeNodeWithPath:path];
        line.strokeColor = colors[index];
        line.lineWidth = widths[index];
        line.lineCap = kCGLineCapRound;
        line.lineJoin = kCGLineJoinRound;
        line.zPosition = 20.0 + index;
        [self.sceneWorld addChild:line];
    }
    CGPathRelease(path);
}

- (void)addSceneNote:(CircuitNote *)note {
    CGRect frame = note.frame;
    CGPathRef path = CGPathCreateWithRoundedRect(CGRectMake(0.0, 0.0, frame.size.width, frame.size.height),
                                                 18.0, 18.0, NULL);
    SKShapeNode *card = [SKShapeNode shapeNodeWithPath:path];
    CGPathRelease(path);
    card.position = frame.origin;
    card.fillColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    card.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.28];
    card.lineWidth = 4.0;
    card.zPosition = 10.0;
    [self.sceneWorld addChild:card];

    CGMutablePathRef handlePath = CGPathCreateMutable();
    CGPathMoveToPoint(handlePath, NULL, CGRectGetMaxX(frame) - 44.0, CGRectGetMaxY(frame));
    CGPathAddLineToPoint(handlePath, NULL, CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 44.0);
    SKShapeNode *handle = [SKShapeNode shapeNodeWithPath:handlePath];
    CGPathRelease(handlePath);
    handle.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    handle.lineWidth = 5.0;
    handle.lineCap = kCGLineCapRound;
    handle.zPosition = 12.0;
    [self.sceneWorld addChild:handle];

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-Medium"];
    label.text = note.text.length ? note.text : @"Note";
    label.fontSize = 28.0;
    label.fontColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = MAX(40.0, frame.size.width - 40.0);
    label.position = CGPointMake(CGRectGetMinX(frame) + 20.0, CGRectGetMinY(frame) + 20.0);
    label.yScale = -1.0;
    label.zPosition = 11.0;
    [self.sceneWorld addChild:label];
}

- (void)addSceneMomentaryButton:(CircuitObject *)object {
    CGRect hitRect = momentaryButtonCapRect(object);
    CGPoint center = CGPointMake(CGRectGetMidX(hitRect), CGRectGetMidY(hitRect));

    SKShapeNode *bezel = [SKShapeNode shapeNodeWithCircleOfRadius:62.0];
    bezel.position = center;
    bezel.fillColor = [UIColor colorWithWhite:0.38 alpha:1.0];
    bezel.strokeColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    bezel.lineWidth = 5.0;
    bezel.zPosition = 120.0;
    [self.sceneWorld addChild:bezel];

    CGFloat capRadius = object->out ? 46.0 : 53.0;
    SKShapeNode *cap = [SKShapeNode shapeNodeWithCircleOfRadius:capRadius];
    cap.position = center;
    cap.fillColor = object->out
        ? [UIColor colorWithRed:0.30 green:0.78 blue:0.22 alpha:1.0]
        : [UIColor colorWithWhite:0.94 alpha:1.0];
    cap.strokeColor = object->out
        ? [UIColor colorWithRed:0.08 green:0.32 blue:0.06 alpha:1.0]
        : [UIColor colorWithWhite:0.62 alpha:1.0];
    cap.lineWidth = 5.0;
    cap.zPosition = 121.0;
    [self.sceneWorld addChild:cap];

    SKShapeNode *highlight = [SKShapeNode shapeNodeWithCircleOfRadius:MAX(8.0, capRadius - 12.0)];
    highlight.position = center;
    highlight.fillColor = UIColor.clearColor;
    highlight.strokeColor = object->out
        ? [UIColor colorWithRed:0.62 green:0.94 blue:0.55 alpha:0.82]
        : [UIColor colorWithWhite:1.0 alpha:0.72];
    highlight.lineWidth = 3.0;
    highlight.zPosition = 122.0;
    [self.sceneWorld addChild:highlight];
}

- (void)addSceneColoredLED:(CircuitObject *)object atWorldPoint:(CGPoint)point {
    UIImage *image;
    SKTexture *texture;
    if (object->type == &CircuitProcessLightBlue) {
        image = self.ledOnBlueImage;
        texture = self.ledOnBlueTexture;
    } else if (object->type == &CircuitProcessLightGreen) {
        image = self.ledOnGreenImage;
        texture = self.ledOnGreenTexture;
    } else {
        image = self.ledOnRedImage;
        texture = self.ledOnRedTexture;
    }
    if (!texture) {
        texture = [SKTexture textureWithImage:image];
        texture.filteringMode = SKTextureFilteringLinear;
        if (object->type == &CircuitProcessLightBlue) self.ledOnBlueTexture = texture;
        else if (object->type == &CircuitProcessLightGreen) self.ledOnGreenTexture = texture;
        else self.ledOnRedTexture = texture;
    }
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithTexture:texture];
    sprite.size = CGSizeMake(ledOnGreen.width, ledOnGreen.height);
    sprite.position = CGPointMake(point.x + ledOnGreen.width * 0.5,
                                  point.y + ledOnGreen.height * 0.5);
    sprite.yScale = -1.0;
    sprite.zPosition = 100.0 + self.sceneWorld.children.count * 0.001;
    [self.sceneWorld addChild:sprite];
}

- (void)addSceneObject:(CircuitObject *)object {
    CGPoint pos = CGPointMake(object->pos.x, object->pos.y);
    if (expandDrawGate(object)) {
        [self addSceneSprite:gateBackgroundTop atWorldPoint:pos];
        CGFloat middleY = pos.y + gateBackgroundTop.height - 1.0;
        CGFloat middleHeight = vSpacing * 2 * MAX(object->type->numInputs, object->type->numOutputs) + 1.0;
        SpriteTexturePos middleTexture = gateBackgroundMiddle;
        middleTexture.height = middleHeight;
        [self addSceneSprite:middleTexture atWorldPoint:CGPointMake(pos.x, middleY)];
        [self addSceneSprite:gateBackgroundBottom atWorldPoint:CGPointMake(pos.x, middleY + middleHeight - 1.0)];
    } else {
        [self addSceneSprite:gateBackgroundHeight2 atWorldPoint:pos];
    }

    if (object->type == &CircuitProcessPushButton) {
        [self addSceneMomentaryButton:object];
    } else if (object->type == &CircuitProcessIn || object->type == &CircuitProcessButton) {
        [self addSceneSprite:object->out ? switchOn : switchOff atWorldPoint:CGPointMake(pos.x - 50.0, pos.y - 50.0)];
    } else if (object->type == &CircuitProcessLight || object->type == &CircuitProcessLightGreen || object->type == &CircuitProcessLightBlue) {
        CGPoint ledPosition = CGPointMake(pos.x + 70.0, pos.y - 85.0);
        if (object->in) [self addSceneColoredLED:object atWorldPoint:ledPosition];
        else [self addSceneSprite:ledOff atWorldPoint:ledPosition];
    } else if (object->type == &CircuitProcessLightWhite) {
        [self addSceneSprite:object->in ? ledOnWhite : ledOff atWorldPoint:CGPointMake(pos.x + 70.0, pos.y - 85.0)];
    } else {
        [self addSceneSprite:[self textureForProcess:object->type] atWorldPoint:CGPointMake(pos.x + 9.0, pos.y)];
    }

    if (object->type == &CircuitProcessMux || object->type == &CircuitProcessMux4 || object->type == &CircuitProcessMux8) {
        [self addSceneSprite:letterX atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
    } else if (object->type == &CircuitProcessCounter4) {
        [self addSceneSprite:letterC atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
    } else if (object->name[0] && !object->name[1]) {
        SpriteTexturePos *letter = letterTable[(unsigned char)object->name[0]];
        if (letter) [self addSceneSprite:*letter atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
    }

    for (int index = 0; index < object->type->numOutputs; index++) {
        GLKVector3 dotPos = offsetForOutlet(object->type, index);
        BOOL connected = object->outputs[index] != NULL || (object == _currentEditingLinkSource && index == _currentEditingLinkSourceIndex);
        SpriteTexturePos texture = (object->out & 1 << index)
            ? (connected ? gateOutletActiveConnected : gateOutletActive)
            : (connected ? gateOutletInactiveConnected : gateOutletInactive);
        [self addSceneSprite:texture atWorldPoint:CGPointMake(pos.x + dotPos.x, pos.y + dotPos.y)];
    }
    for (int index = 0; index < object->type->numInputs; index++) {
        GLKVector3 dotPos = offsetForInlet(object->type, index);
        BOOL connected = object->inputs[index] != NULL || (object == _currentEditingLinkTarget && index == _currentEditingLinkTargetIndex);
        SpriteTexturePos texture = (object->in & 1 << index)
            ? (connected ? gateOutletActiveConnected : gateOutletActive)
            : (connected ? gateOutletInactiveConnected : gateOutletInactive);
        [self addSceneSprite:texture atWorldPoint:CGPointMake(pos.x + dotPos.x, pos.y + dotPos.y)];
    }

    if (object->type == &CircuitProcess7Seg || object->type == &CircuitProcess7SegBin) {
        BOOL compact = object->type == &CircuitProcess7SegBin;
        static const unsigned char digitSegments[] = {
            0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111,
            0b1111111, 0b1101111, 0b1110111, 0b1111100, 0b1011000, 0b1011110, 0b1111001, 0b1110001
        };
        int segments = compact ? digitSegments[object->in & 0xf] : object->in & 0xff;
        SpriteTexturePos texture = sevenSegment;
        texture.twidth /= 16.0;
        texture.theight /= 8.0;
        texture.u += (segments % 16) * texture.twidth;
        texture.v += (segments / 16) * texture.theight;
        texture.width = compact ? 120.0 : 240.0;
        texture.height = compact ? 200.0 : 400.0;
        CGPoint displayPos = compact ? CGPointMake(pos.x + 100.0, pos.y + 40.0) : CGPointMake(pos.x + 40.0, pos.y + 40.0);
        [self addSceneSprite:texture atWorldPoint:displayPos];
    }
}

- (void)addSceneHighlightAt:(GLKVector2)position progress:(CGFloat)progress {
    if (progress > 1.0) return;
    CGFloat radius = 24.0 + 60.0 * progress;
    SKShapeNode *highlight = [SKShapeNode shapeNodeWithCircleOfRadius:radius];
    highlight.position = CGPointMake(position.x, position.y);
    highlight.strokeColor = [UIColor colorWithWhite:1.0 alpha:MAX(0.0, 1.0 - progress)];
    highlight.lineWidth = MAX(2.0 / MAX(_scale.x, 0.001), 4.0);
    highlight.zPosition = 200.0;
    [self.sceneWorld addChild:highlight];
}

- (void)rebuildSceneContent {
    [self.sceneWorld removeAllChildren];
    Circuit *circuit = self.document.circuit;
    for (CircuitNote *note in circuit.notes) {
        [self addSceneNote:note];
    }
    [circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        for (int sourceIndex = 0; sourceIndex < object->type->numOutputs; sourceIndex++) {
            CircuitLink *link = object->outputs[sourceIndex];
            while (link) {
                GLKVector3 dotPos = offsetForOutlet(object->type, sourceIndex);
                GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
                dotPos = offsetForInlet(link->target->type, link->targetIndex);
                GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
                [self addSceneLinkFrom:A to:B active:!!(object->out & 1 << sourceIndex)];
                link = link->nextSibling;
            }
        }
    }];
    if (_currentEditingLinkSource && !_currentEditingLink) {
        CircuitObject *object = _currentEditingLinkSource;
        GLKVector3 dotPos = offsetForOutlet(object->type, _currentEditingLinkSourceIndex);
        GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
        GLKVector2 B = GLKVector2Make(_currentEditingLinkTargetPosition.x + radius, _currentEditingLinkTargetPosition.y + radius);
        [self addSceneLinkFrom:A to:B active:!!(object->out & 1 << _currentEditingLinkSourceIndex)];
    }
    [circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        [self addSceneObject:object];
    }];
    [self addSceneHighlightAt:_highlightLinkLocation progress:_highlightProgress];
    [self addSceneHighlightAt:_highlightOutLinkLocation progress:_highlightOutProgress];
    self.sceneContentNeedsUpdate = NO;
}

- (void)attachToScene:(SKScene *)scene backgroundImage:(UIImage *)backgroundImage {
    self.scene = scene;
    [scene removeAllChildren];
    self.sceneBackground = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:backgroundImage]];
    self.sceneBackground.zPosition = 0;
    [scene addChild:self.sceneBackground];
    self.sceneGrid = [SKShapeNode node];
    self.sceneGrid.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.sceneGrid.lineWidth = 1.0;
    self.sceneGrid.zPosition = 1;
    [scene addChild:self.sceneGrid];
    self.sceneWorld = [SKNode node];
    self.sceneWorld.zPosition = 2;
    [scene addChild:self.sceneWorld];
    self.sceneContentNeedsUpdate = YES;
}

- (void)setSceneContentNeedsUpdate {
    self.sceneContentNeedsUpdate = YES;
}

- (void)updateSceneForViewSize:(CGSize)viewSize allowContentRebuild:(BOOL)allowContentRebuild {
    if (!self.scene) return;
    self.sceneBackground.position = CGPointMake(viewSize.width * 0.5, viewSize.height * 0.5);
    self.sceneBackground.size = viewSize;

    self.sceneWorld.position = CGPointMake(_translate.x, viewSize.height - _translate.y);
    self.sceneWorld.xScale = _scale.x;
    self.sceneWorld.yScale = -_scale.y;

    CGFloat scale = _scale.x ?: 1.0;
    CGFloat factor = round(log2f(scale));
    CGFloat grid = (60.0 / exp2f(factor)) * scale;
    CGFloat startX = fmod(_translate.x, grid);
    CGFloat startY = fmod(_translate.y, grid);
    if (startX > 0.0) startX -= grid;
    if (startY > 0.0) startY -= grid;
    CGMutablePathRef gridPath = CGPathCreateMutable();
    for (CGFloat x = startX; x < viewSize.width; x += grid) {
        CGPathMoveToPoint(gridPath, NULL, x, 0.0);
        CGPathAddLineToPoint(gridPath, NULL, x, viewSize.height);
    }
    for (CGFloat y = startY; y < viewSize.height; y += grid) {
        CGFloat sceneY = viewSize.height - y;
        CGPathMoveToPoint(gridPath, NULL, 0.0, sceneY);
        CGPathAddLineToPoint(gridPath, NULL, viewSize.width, sceneY);
    }
    self.sceneGrid.path = gridPath;
    CGPathRelease(gridPath);

    if (allowContentRebuild && self.sceneContentNeedsUpdate) {
        [self rebuildSceneContent];
    }
}

- (void)drawSprite:(SpriteTexturePos)texture atWorldPoint:(CGPoint)point {
    UIImage *image = [self.atlas imageForSprite:texture];
    if (!image) return;
    CGRect rect = [self screenRectForWorldRect:CGRectMake(point.x, point.y, texture.width, texture.height)];
    [image drawInRect:rect];
}

- (void)drawGridInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.12].CGColor);
    CGContextSetLineWidth(context, 1.0);

    CGFloat scale = _scale.x ?: 1.0;
    CGFloat factor = round(log2f(scale));
    CGFloat gridWorld = 60.0 / exp2f(factor);
    CGFloat grid = gridWorld * scale;
    CGFloat startX = fmod(_translate.x, grid);
    CGFloat startY = fmod(_translate.y, grid);
    if (startX > 0.0) startX -= grid;
    if (startY > 0.0) startY -= grid;

    for (CGFloat x = startX; x < rect.size.width; x += grid) {
        CGContextMoveToPoint(context, x, 0);
        CGContextAddLineToPoint(context, x, rect.size.height);
    }
    for (CGFloat y = startY; y < rect.size.height; y += grid) {
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, rect.size.width, y);
    }
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawLinkFrom:(GLKVector2)A to:(GLKVector2)B active:(BOOL)isActive {
    CGPoint a = [self screenPointForWorldPoint:CGPointMake(A.x, A.y)];
    CGPoint b = [self screenPointForWorldPoint:CGPointMake(B.x, B.y)];
    CGFloat dx = (b.x - a.x) / 2.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:a];
    [path addCurveToPoint:b controlPoint1:CGPointMake(a.x + dx, a.y) controlPoint2:CGPointMake(b.x - dx, b.y)];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;

    CGFloat width = MAX(7.0, 16.0 * _scale.x);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(1.0, 1.0), 0.0, [UIColor colorWithWhite:0.0 alpha:0.9].CGColor);

    path.lineWidth = width;
    UIColor *edgeColor = isActive ? [UIColor colorWithRed:0.0 green:0.22 blue:0.03 alpha:1.0] : [UIColor colorWithWhite:0.08 alpha:1.0];
    [edgeColor setStroke];
    [path stroke];
    CGContextRestoreGState(context);

    path.lineWidth = width - 2.0;
    UIColor *bodyColor = isActive ? [UIColor colorWithRed:0.0 green:0.72 blue:0.09 alpha:1.0] : [UIColor colorWithWhite:0.68 alpha:1.0];
    [bodyColor setStroke];
    [path stroke];

    path.lineWidth = MAX(2.0, width * 0.38);
    UIColor *highlightColor = isActive ? [UIColor colorWithRed:0.48 green:1.0 blue:0.53 alpha:1.0] : [UIColor colorWithWhite:0.9 alpha:1.0];
    [highlightColor setStroke];
    [path stroke];
}

- (void)drawSevenSegmentAt:(CGPoint)position input:(int)input compact:(BOOL)compact {
    static const unsigned char digitSegments[] = {
        0b0111111, 0b0000110, 0b1011011, 0b1001111,
        0b1100110, 0b1101101, 0b1111101, 0b0000111,
        0b1111111, 0b1101111, 0b1110111, 0b1111100,
        0b1011000, 0b1011110, 0b1111001, 0b1110001
    };
    int segments = compact ? digitSegments[input & 0xf] : input & 0xff;

    SpriteTexturePos texture = sevenSegment;
    texture.twidth /= 16.0;
    texture.theight /= 8.0;
    texture.u += (segments % 16) * texture.twidth;
    texture.v += (segments / 16) * texture.theight;
    texture.width = compact ? 120.0 : 240.0;
    texture.height = compact ? 200.0 : 400.0;
    [self drawSprite:texture atWorldPoint:position];
}

- (void)drawObject:(CircuitObject *)object {
    CGPoint pos = CGPointMake(object->pos.x, object->pos.y);

    if (expandDrawGate(object)) {
        [self drawSprite:gateBackgroundTop atWorldPoint:pos];
        CGFloat middleY = pos.y + gateBackgroundTop.height - 1.0;
        CGFloat middleHeight = vSpacing * 2 * MAX(object->type->numInputs, object->type->numOutputs) + 1.0;
        UIImage *middle = [self.atlas imageForSprite:gateBackgroundMiddle];
        [middle drawInRect:[self screenRectForWorldRect:CGRectMake(pos.x, middleY, gateBackgroundMiddle.width, middleHeight)]];
        [self drawSprite:gateBackgroundBottom atWorldPoint:CGPointMake(pos.x, middleY + middleHeight - 1.0)];
    } else {
        [self drawSprite:gateBackgroundHeight2 atWorldPoint:pos];
    }

    if (object->type == &CircuitProcessPushButton) {
        CGRect hitRect = momentaryButtonCapRect(object);
        CGPoint center = CGPointMake(CGRectGetMidX(hitRect), CGRectGetMidY(hitRect));
        CGRect bezelRect = [self screenRectForWorldRect:CGRectMake(center.x - 62.0, center.y - 62.0, 124.0, 124.0)];
        UIBezierPath *bezel = [UIBezierPath bezierPathWithOvalInRect:bezelRect];
        [[UIColor colorWithWhite:0.38 alpha:1.0] setFill];
        [bezel fill];
        [[UIColor colorWithWhite:0.82 alpha:1.0] setStroke];
        bezel.lineWidth = MAX(2.0, 5.0 * _scale.x);
        [bezel stroke];

        CGFloat capRadius = object->out ? 46.0 : 53.0;
        CGRect capRect = [self screenRectForWorldRect:CGRectMake(center.x - capRadius,
                                                                 center.y - capRadius,
                                                                 capRadius * 2.0,
                                                                 capRadius * 2.0)];
        UIBezierPath *cap = [UIBezierPath bezierPathWithOvalInRect:capRect];
        UIColor *capFill = object->out
            ? [UIColor colorWithRed:0.30 green:0.78 blue:0.22 alpha:1.0]
            : [UIColor colorWithWhite:0.94 alpha:1.0];
        UIColor *capStroke = object->out
            ? [UIColor colorWithRed:0.08 green:0.32 blue:0.06 alpha:1.0]
            : [UIColor colorWithWhite:0.62 alpha:1.0];
        [capFill setFill];
        [cap fill];
        [capStroke setStroke];
        cap.lineWidth = MAX(2.0, 5.0 * _scale.x);
        [cap stroke];
    } else if (object->type == &CircuitProcessIn || object->type == &CircuitProcessButton) {
        [self drawSprite:object->out ? switchOn : switchOff atWorldPoint:CGPointMake(pos.x - 50.0, pos.y - 50.0)];
    } else if (object->type == &CircuitProcessLight || object->type == &CircuitProcessLightGreen || object->type == &CircuitProcessLightBlue) {
        CGPoint ledPosition = CGPointMake(pos.x + 70.0, pos.y - 85.0);
        if (object->in) {
            UIImage *image = object->type == &CircuitProcessLightBlue ? self.ledOnBlueImage :
                (object->type == &CircuitProcessLightGreen ? self.ledOnGreenImage : self.ledOnRedImage);
            CGRect rect = [self screenRectForWorldRect:CGRectMake(ledPosition.x, ledPosition.y, ledOnGreen.width, ledOnGreen.height)];
            [image drawInRect:rect];
        } else {
            [self drawSprite:ledOff atWorldPoint:ledPosition];
        }
    } else if (object->type == &CircuitProcessLightWhite) {
        [self drawSprite:object->in ? ledOnWhite : ledOff atWorldPoint:CGPointMake(pos.x + 70.0, pos.y - 85.0)];
    } else {
        [self drawSprite:[self textureForProcess:object->type] atWorldPoint:CGPointMake(pos.x + 9.0, pos.y)];
    }

    if (object->type == &CircuitProcessMux || object->type == &CircuitProcessMux4 || object->type == &CircuitProcessMux8) {
        [self drawSprite:letterX atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
    } else if (object->type == &CircuitProcessCounter4) {
        [self drawSprite:letterC atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
    } else if (object->name[0] && !object->name[1]) {
        SpriteTexturePos *letter = letterTable[(unsigned char)object->name[0]];
        if (letter) {
            [self drawSprite:*letter atWorldPoint:CGPointMake(pos.x + 105.0, pos.y + 43.0)];
        }
    }


    for(int o = 0; o < object->type->numOutputs; o++) {
        GLKVector3 dotPos = offsetForOutlet(object->type, o);
        BOOL isConnected = object->outputs[o] != NULL;
        if (object == _currentEditingLinkSource && o == _currentEditingLinkSourceIndex) isConnected = YES;
        SpriteTexturePos texture = (object->out & 1 << o) ? (isConnected ? gateOutletActiveConnected : gateOutletActive) : (isConnected ? gateOutletInactiveConnected : gateOutletInactive);
        [self drawSprite:texture atWorldPoint:CGPointMake(pos.x + dotPos.x, pos.y + dotPos.y)];
    }

    for(int o = 0; o < object->type->numInputs; o++) {
        GLKVector3 dotPos = offsetForInlet(object->type, o);
        BOOL isConnected = object->inputs[o] != NULL;
        if (object == _currentEditingLinkTarget && o == _currentEditingLinkTargetIndex) isConnected = YES;
        SpriteTexturePos texture = (object->in & 1 << o) ? (isConnected ? gateOutletActiveConnected : gateOutletActive) : (isConnected ? gateOutletInactiveConnected : gateOutletInactive);
        [self drawSprite:texture atWorldPoint:CGPointMake(pos.x + dotPos.x, pos.y + dotPos.y)];
    }
}

- (void)drawHighlightAt:(GLKVector2)position progress:(CGFloat)progress {
    if (progress > 1.0) return;
    CGPoint center = [self screenPointForWorldPoint:CGPointMake(position.x, position.y)];
    CGFloat r = (24.0 + 60.0 * progress) * _scale.x;
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - r, center.y - r, r * 2.0, r * 2.0)];
    [[UIColor colorWithWhite:1.0 alpha:MAX(0.0, 1.0 - progress)] setStroke];
    path.lineWidth = MAX(2.0, 4.0 * _scale.x);
    [path stroke];
}

- (void)drawNote:(CircuitNote *)note {
    CGRect rect = [self screenRectForWorldRect:note.frame];
    CGFloat cornerRadius = MAX(4.0, 18.0 * _scale.x);
    UIBezierPath *card = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    [[UIColor colorWithWhite:1.0 alpha:0.10] setFill];
    [card fill];
    [[UIColor colorWithWhite:1.0 alpha:0.28] setStroke];
    card.lineWidth = MAX(1.0, 4.0 * _scale.x);
    [card stroke];

    UIBezierPath *handle = [UIBezierPath bezierPath];
    [handle moveToPoint:CGPointMake(CGRectGetMaxX(rect) - 44.0 * _scale.x, CGRectGetMaxY(rect))];
    [handle addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect) - 44.0 * _scale.y)];
    handle.lineWidth = MAX(1.0, 5.0 * _scale.x);
    handle.lineCapStyle = kCGLineCapRound;
    [[UIColor colorWithWhite:1.0 alpha:0.35] setStroke];
    [handle stroke];

    CGFloat inset = MAX(8.0, 20.0 * _scale.x);
    CGRect textRect = CGRectInset(rect, inset, inset);
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:MAX(10.0, 28.0 * _scale.x) weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.92],
        NSParagraphStyleAttributeName: paragraph
    };
    [(note.text.length ? note.text : @"Note") drawInRect:textRect withAttributes:attributes];
}

- (void)drawInRect:(CGRect)rect {
    [self drawGridInRect:rect];

    Circuit *_circuit = self.document.circuit;
    for (CircuitNote *note in _circuit.notes) {
        [self drawNote:note];
    }
    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        for(int sourceIndex = 0; sourceIndex < object->type->numOutputs; sourceIndex++) {
            CircuitLink *link = object->outputs[sourceIndex];
            while(link) {
                GLKVector3 dotPos = offsetForOutlet(object->type, sourceIndex);
                GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
                dotPos = offsetForInlet(link->target->type, link->targetIndex);
                GLKVector2 B = GLKVector2Make(link->target->pos.x + dotPos.x + radius, link->target->pos.y + dotPos.y + radius);
                BOOL isActive = object->out & 1 << sourceIndex;
                [self drawLinkFrom:A to:B active:isActive];
                link = link->nextSibling;
            }
        }
    }];

    if (_currentEditingLinkSource && !_currentEditingLink) {
        CircuitObject *object = _currentEditingLinkSource;
        GLKVector3 dotPos = offsetForOutlet(object->type, _currentEditingLinkSourceIndex);
        GLKVector2 A = GLKVector2Make(object->pos.x + dotPos.x + radius, object->pos.y + dotPos.y + radius);
        GLKVector2 B = GLKVector2Make(_currentEditingLinkTargetPosition.x + radius, _currentEditingLinkTargetPosition.y + radius);
        BOOL isActive = object->out & 1 << _currentEditingLinkSourceIndex;
        [self drawLinkFrom:A to:B active:isActive];
    }

    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        [self drawObject:object];
    }];

    [_circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        if (object->type == &CircuitProcess7Seg) {
            [self drawSevenSegmentAt:CGPointMake(object->pos.x + 40.0, object->pos.y + 40.0) input:object->in compact:NO];
        } else if (object->type == &CircuitProcess7SegBin) {
            [self drawSevenSegmentAt:CGPointMake(object->pos.x + 100.0, object->pos.y + 40.0) input:object->in compact:YES];
        }
    }];

    [self drawHighlightAt:_highlightLinkLocation progress:_highlightProgress];
    [self drawHighlightAt:_highlightOutLinkLocation progress:_highlightOutProgress];
}

@end
