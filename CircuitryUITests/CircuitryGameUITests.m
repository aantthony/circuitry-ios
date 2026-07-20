#import <XCTest/XCTest.h>

@interface CircuitryGameUITests : XCTestCase
@end

@implementation CircuitryGameUITests

- (XCUICoordinate *)point:(CGVector)point inApp:(XCUIApplication *)app
{
    CGSize appSize = app.frame.size;
    return [app coordinateWithNormalizedOffset:CGVectorMake(point.dx / appSize.width,
                                                             point.dy / appSize.height)];
}

- (void)wireFrom:(CGVector)source to:(CGVector)target inApp:(XCUIApplication *)app
{
    // Circuitry intentionally requires a sustained touch before a wire drag.
    [[self point:source inApp:app] pressForDuration:0.7
                            thenDragToCoordinate:[self point:target inApp:app]];
}

- (void)panCanvasRightBy:(CGFloat)distance inApp:(XCUIApplication *)app
{
    CGSize appSize = app.frame.size;
    XCUICoordinate *start = [self point:CGVectorMake(appSize.width * 0.70,
                                                     appSize.height * 0.65) inApp:app];
    XCUICoordinate *end = [self point:CGVectorMake(appSize.width * 0.70 + distance,
                                                   appSize.height * 0.65) inApp:app];
    [start pressForDuration:0.1
       thenDragToCoordinate:end
               withVelocity:100.0
        thenHoldForDuration:0.2];
}

- (void)panCanvasRightInApp:(XCUIApplication *)app
{
    [self panCanvasRightBy:115.0 inApp:app];
}

- (NSArray<NSValue *> *)portCenters:(XCUIApplication *)app
{
    NSMutableArray<NSValue *> *ports = [NSMutableArray array];
    CGSize appSize = app.frame.size;
    CGFloat canvasLeft = MAX(230.0, appSize.width * 0.24);
    CGFloat canvasBottom = appSize.height - 180.0;
    NSString *snapshot = app.debugDescription;
    NSRegularExpression *frames = [NSRegularExpression
        regularExpressionWithPattern:@"\\{\\{(-?[0-9.]+), (-?[0-9.]+)\\}, \\{(-?[0-9.]+), (-?[0-9.]+)\\}\\}"
        options:0 error:nil];

    for (NSTextCheckingResult *match in [frames matchesInString:snapshot
                                                        options:0
                                                          range:NSMakeRange(0, snapshot.length)]) {
        CGFloat x = [[snapshot substringWithRange:[match rangeAtIndex:1]] doubleValue];
        CGFloat y = [[snapshot substringWithRange:[match rangeAtIndex:2]] doubleValue];
        CGFloat width = [[snapshot substringWithRange:[match rangeAtIndex:3]] doubleValue];
        CGFloat height = [[snapshot substringWithRange:[match rangeAtIndex:4]] doubleValue];
        if (width > 13.0 && width < 16.0 && height > 14.0 && height < 16.0 &&
            x > canvasLeft && y + height < canvasBottom) {
            [ports addObject:[NSValue valueWithCGVector:
                CGVectorMake(x + width / 2.0, y + height / 2.0)]];
        }
    }
    return ports;
}

- (NSString *)keyForPort:(CGVector)port
{
    return [NSString stringWithFormat:@"%.1f,%.1f", port.dx, port.dy];
}

- (CGVector)nearestPortTo:(CGVector)target inPorts:(NSArray<NSValue *> *)ports
{
    CGVector best = target;
    CGFloat bestDistance = CGFLOAT_MAX;
    for (NSValue *value in ports) {
        CGVector port = value.CGVectorValue;
        CGFloat distance = hypot(port.dx - target.dx, port.dy - target.dy);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = port;
        }
    }
    XCTAssertLessThan(bestDistance, 25.0, @"No visible port near %.0f,%.0f", target.dx, target.dy);
    return best;
}

- (NSArray<NSValue *> *)createGateNamed:(NSString *)name
                                 inputs:(NSInteger)inputCount
                                outputs:(NSInteger)outputCount
                               atOrigin:(CGVector)origin
                                  inApp:(XCUIApplication *)app
{
    NSMutableSet<NSString *> *before = [NSMutableSet set];
    for (NSValue *value in [self portCenters:app]) {
        [before addObject:[self keyForPort:value.CGVectorValue]];
    }

    XCUIElement *tool = [app.staticTexts matchingIdentifier:name].firstMatch;
    XCTAssertTrue(tool.hittable, @"Toolbelt item %@ is not visible", name);
    [tool tap];

    NSArray<NSValue *> *added = [self newlyAddedGateWithInputs:inputCount
                                                       outputs:outputCount
                                                   excluding:before
                                                       inApp:app];
    XCTAssertEqual(added.count, inputCount + outputCount);
    if (added.count != inputCount + outputCount) return @[];

    CGFloat inputY = 0;
    CGFloat inputX = [added[0] CGVectorValue].dx;
    for (NSInteger index = 0; index < inputCount; index++) {
        inputY += [added[index] CGVectorValue].dy;
    }
    inputY /= inputCount;
    CGVector currentCenter = CGVectorMake(inputX + 62.25, inputY + 0.75);
    CGFloat desiredY = origin.dy + (inputCount == 1 ? 40.0 : 23.25 + 16.5 * (inputCount - 1));
    [[self point:currentCenter inApp:app] pressForDuration:0.1
        thenDragToCoordinate:[self point:CGVectorMake(origin.dx + 77.0, desiredY) inApp:app]];

    // Use the snapped accessibility geometry rather than predicting the drop.
    NSArray<NSValue *> *allPorts = [self portCenters:app];
    NSArray<NSValue *> *moved = [self gateNearestOrigin:origin
                                                inputs:inputCount
                                               outputs:outputCount
                                               inPorts:allPorts];
    XCTAssertEqual(moved.count, inputCount + outputCount);
    return moved;
}

- (NSArray<NSValue *> *)newlyAddedGateWithInputs:(NSInteger)inputCount
                                          outputs:(NSInteger)outputCount
                                        excluding:(NSSet<NSString *> *)before
                                            inApp:(XCUIApplication *)app
{
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3.0];
    while (deadline.timeIntervalSinceNow > 0) {
        NSArray<NSValue *> *ports = [self portCenters:app];
        for (NSValue *topValue in ports) {
            NSArray<NSValue *> *gate = [self gateStartingAt:topValue.CGVectorValue
                                                     inputs:inputCount
                                                    outputs:outputCount
                                                    inPorts:ports];
            if (gate.count != inputCount + outputCount) continue;
            BOOL entirelyOld = YES;
            for (NSValue *value in gate) {
                entirelyOld &= [before containsObject:[self keyForPort:value.CGVectorValue]];
            }
            if (!entirelyOld) return gate;
        }
    }
    return @[];
}

- (NSArray<NSValue *> *)gateNearestOrigin:(CGVector)origin
                                    inputs:(NSInteger)inputCount
                                   outputs:(NSInteger)outputCount
                                   inPorts:(NSArray<NSValue *> *)ports
{
    NSArray<NSValue *> *best = @[];
    CGFloat bestDistance = CGFLOAT_MAX;
    for (NSValue *topValue in ports) {
        NSArray<NSValue *> *gate = [self gateStartingAt:topValue.CGVectorValue
                                                 inputs:inputCount outputs:outputCount inPorts:ports];
        if (gate.count != inputCount + outputCount) continue;
        CGVector top = topValue.CGVectorValue;
        CGFloat inferredY = top.dy - (inputCount == 1 ? 39.0 : 22.5);
        CGFloat distance = hypot((top.dx - 14.75) - origin.dx, inferredY - origin.dy);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = gate;
        }
    }
    return best;
}

- (NSArray<NSValue *> *)gateStartingAt:(CGVector)top
                                 inputs:(NSInteger)inputCount
                                outputs:(NSInteger)outputCount
                                inPorts:(NSArray<NSValue *> *)ports
{
    NSMutableArray<NSValue *> *inputs = [NSMutableArray array];
    NSMutableArray<NSValue *> *outputs = [NSMutableArray array];
    for (NSInteger index = 0; index < inputCount; index++) {
        CGFloat y = top.dy + (inputCount == 1 ? 0 : 33.0 * index);
        NSValue *port = [self portNear:CGVectorMake(top.dx, y) inPorts:ports tolerance:3.0];
        if (port) [inputs addObject:port];
    }
    CGFloat outputY = top.dy + (outputCount == 1 && inputCount > 1 ? 16.5 : 0);
    for (NSInteger index = 0; index < outputCount; index++) {
        CGFloat y = outputY + (outputCount == 1 ? 0 : 33.0 * index);
        NSValue *port = [self portNear:CGVectorMake(top.dx + 124.0, y) inPorts:ports tolerance:4.0];
        if (port) [outputs addObject:port];
    }
    if (inputs.count != inputCount || outputs.count != outputCount) return @[];
    [inputs addObjectsFromArray:outputs];
    return inputs;
}

- (NSValue *)portNear:(CGVector)target
              inPorts:(NSArray<NSValue *> *)ports
            tolerance:(CGFloat)tolerance
{
    for (NSValue *value in ports) {
        CGVector port = value.CGVectorValue;
        if (fabs(port.dx - target.dx) < tolerance && fabs(port.dy - target.dy) < tolerance) {
            return value;
        }
    }
    return nil;
}

- (void)openProblem:(NSString *)title number:(NSInteger)number inApp:(XCUIApplication *)app
{
    XCUIElement *problem = app.staticTexts[title];
    for (NSInteger attempt = 0; attempt < 10 && !problem.hittable; attempt++) [app swipeUp];
    XCTAssertTrue(problem.hittable, @"Problem %@ is locked or absent", title);
    [problem tap];
    NSString *heading = [NSString stringWithFormat:@"Problem #%ld - %@", (long)number, title];
    XCTAssertTrue([app.staticTexts[heading] waitForExistenceWithTimeout:10]);
}

- (void)assertCheckerPasses:(XCUIApplication *)app
{
    [app.buttons[@"Check Answer"] tap];
    XCTAssertTrue([app.buttons[@"OK"] waitForExistenceWithTimeout:10]);
    XCTAssertEqual([app.images matchingIdentifier:@"TestResultMismatch"].count, 0u);
}

- (void)buildTwoOfThreeScreenshotCircuitInApp:(XCUIApplication *)app
{
    NSArray<NSValue *> *basePorts = [[self portCenters:app]
        sortedArrayUsingComparator:^NSComparisonResult(NSValue *left, NSValue *right) {
            CGVector a = left.CGVectorValue;
            CGVector b = right.CGVectorValue;
            if (a.dx < b.dx) return NSOrderedAscending;
            if (a.dx > b.dx) return NSOrderedDescending;
            return a.dy < b.dy ? NSOrderedAscending : NSOrderedDescending;
        }];
    XCTAssertEqual(basePorts.count, 4u);
    if (basePorts.count != 4) return;

    NSArray<NSValue *> *inputs = [[basePorts subarrayWithRange:NSMakeRange(0, 3)]
        sortedArrayUsingComparator:^NSComparisonResult(NSValue *top, NSValue *bottom) {
            return top.CGVectorValue.dy < bottom.CGVectorValue.dy
                ? NSOrderedAscending : NSOrderedDescending;
        }];
    CGVector a = inputs[0].CGVectorValue;
    CGVector b = inputs[1].CGVectorValue;
    CGVector output = basePorts.lastObject.CGVectorValue;

    CGFloat gateX = a.dx + 90.0;
    NSArray<NSValue *> *xorGate = [self createGateNamed:@"XOR" inputs:2 outputs:1
                                               atOrigin:CGVectorMake(gateX, a.dy - 70.0) inApp:app];
    NSArray<NSValue *> *andGate = [self createGateNamed:@"AND" inputs:2 outputs:1
                                               atOrigin:CGVectorMake(gateX, b.dy + 90.0) inApp:app];
    NSArray<NSValue *> *notGate = [self createGateNamed:@"NOT" inputs:1 outputs:1
                                               atOrigin:CGVectorMake(gateX + 210.0, b.dy + 90.0) inApp:app];
    if (xorGate.count != 3 || andGate.count != 3 || notGate.count != 2) return;

    [self wireFrom:a to:[xorGate[0] CGVectorValue] inApp:app];
    [self wireFrom:b to:[xorGate[1] CGVectorValue] inApp:app];
    [self wireFrom:[xorGate[2] CGVectorValue] to:output inApp:app];

    [self wireFrom:a to:[andGate[0] CGVectorValue] inApp:app];
    [self wireFrom:b to:[andGate[1] CGVectorValue] inApp:app];
    [self wireFrom:[andGate[2] CGVectorValue] to:[notGate[0] CGVectorValue] inApp:app];

    [[self point:CGVectorMake(b.dx - 55.0, b.dy) inApp:app] tap];
    [self panCanvasRightInApp:app];

    XCUIElement *problemFooter = app.staticTexts[@"Problem #12 - Exactly Two of Three"];
    XCTAssertTrue(problemFooter.hittable);
    [problemFooter tap];
}

- (void)captureAppStoreScreenshotNamed:(NSString *)name inApp:(XCUIApplication *)app
{
    XCTAssertEqual(app.state, XCUIApplicationStateRunningForeground);

    XCUIScreenshot *screenshot = XCUIScreen.mainScreen.screenshot;
    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:screenshot];
    attachment.name = name;
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

- (void)launchAppForScreenshots:(XCUIApplication *)app
{
    if (app.state != XCUIApplicationStateNotRunning) [app terminate];
    [app launch];
    XCTAssertTrue([app.navigationBars[@"Problems"] waitForExistenceWithTimeout:10]);
    XCTAssertTrue([app.staticTexts[@"Connect an AND Gate"] waitForExistenceWithTimeout:10]);
}

- (void)testGenerateAppStoreScreenshots
{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[
        @"-AppleLanguages", @"(en)",
        @"-AppleLocale", @"en_AU",
        @"-openedBefore", @"YES",
        @"-CurrentLevelIndex", @"999"
    ];
    [self launchAppForScreenshots:app];

    [self captureAppStoreScreenshotNamed:@"03-problems-overview" inApp:app];

    [self openProblem:@"Connect an AND Gate" number:1 inApp:app];
    [self captureAppStoreScreenshotNamed:@"02-guided-problem" inApp:app];
    [self launchAppForScreenshots:app];

    [self openProblem:@"Exactly Two of Three" number:12 inApp:app];
    [self buildTwoOfThreeScreenshotCircuitInApp:app];
    [self captureAppStoreScreenshotNamed:@"01-two-of-three" inApp:app];
    [self launchAppForScreenshots:app];

    [self openProblem:@"Multiply Two-Bit Numbers" number:17 inApp:app];
    [self panCanvasRightBy:170.0 inApp:app];
    XCUIElement *multiplierFooter = app.staticTexts[@"Problem #17 - Multiply Two-Bit Numbers"];
    XCTAssertTrue(multiplierFooter.hittable);
    [multiplierFooter tap];
    [self captureAppStoreScreenshotNamed:@"04-binary-multiplier" inApp:app];
}

- (void)testCompletedProblemGridHasNoLockedCards
{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    NSArray<NSString *> *titles = @[
        @"Connect an AND Gate", @"Build a Three-Input AND", @"Build a Three-Input OR",
        @"Build a NAND Gate", @"Build NOT from NAND", @"Build an XOR Gate",
        @"Combine Two XOR Gates", @"Build OR from NAND", @"Build AND from NAND",
        @"Build NAND from NOR", @"Exactly One of Three", @"Exactly Two of Three",
        @"Add Two Binary Digits", @"Build a Full Adder", @"Add Two-Bit Numbers",
        @"Add Four-Bit Numbers", @"Multiply Two-Bit Numbers", @"Build an SR Latch",
        @"Build a Gated SR Latch", @"Build a JK Flip-Flop", @"Build a Binary Counter"
    ];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    BOOL sawLockedCard = NO;
    for (NSInteger page = 0; page < 10; page++) {
        for (NSString *title in titles) {
            if (app.staticTexts[title].exists) [seen addObject:title];
        }
        sawLockedCard |= [[app.staticTexts matchingIdentifier:@"Locked"] count] > 0;
        if (seen.count == titles.count) break;
        [app swipeUp];
    }
    XCTAssertEqualObjects(seen, [NSSet setWithArray:titles]);
    XCTAssertFalse(sawLockedCard);
}

- (void)testBinaryCounterRecipe
{
    if (![NSProcessInfo.processInfo.environment[@"CIRCUITRY_RUN_COUNTER_RECIPE"] boolValue]) return;

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self openProblem:@"Build a Binary Counter" number:21 inApp:app];

    NSArray<NSValue *> *base = [self portCenters:app];
    CGVector clock = [self nearestPortTo:CGVectorMake(364, 400) inPorts:base];
    CGVector bits[] = {
        [self nearestPortTo:CGVectorMake(490, 419) inPorts:base],
        [self nearestPortTo:CGVectorMake(490, 452) inPorts:base],
        [self nearestPortTo:CGVectorMake(490, 485) inPorts:base],
        [self nearestPortTo:CGVectorMake(490, 518) inPorts:base]
    };
    CGVector origins[] = {
        CGVectorMake(250, 150), CGVectorMake(500, 150),
        CGVectorMake(250, 600), CGVectorMake(500, 600)
    };
    NSMutableArray<NSArray<NSValue *> *> *stages = [NSMutableArray array];
    for (NSInteger index = 0; index < 4; index++) {
        NSArray<NSValue *> *stage = [self createGateNamed:@"T flip-flop" inputs:2 outputs:2
                                                  atOrigin:origins[index] inApp:app];
        [stages addObject:stage];
        [self wireFrom:[stage[2] CGVectorValue] to:bits[index] inApp:app];
    }
    [self wireFrom:clock to:[stages[0][1] CGVectorValue] inApp:app];
    for (NSInteger index = 0; index < 3; index++) {
        // Wire Q-bar before enabling T to avoid a startup edge.
        [self wireFrom:[stages[index][3] CGVectorValue]
                    to:[stages[index + 1][1] CGVectorValue] inApp:app];
    }
    CGVector highOrigins[] = {
        CGVectorMake(250, 300), CGVectorMake(500, 300),
        CGVectorMake(250, 450), CGVectorMake(500, 450)
    };
    for (NSInteger index = 0; index < 4; index++) {
        NSArray<NSValue *> *high = [self createGateNamed:@"NOT" inputs:1 outputs:1
                                                  atOrigin:highOrigins[index] inApp:app];
        [self wireFrom:[high[1] CGVectorValue] to:[stages[index][0] CGVectorValue] inApp:app];
    }
    [self assertCheckerPasses:app];
}

@end
