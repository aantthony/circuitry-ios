#import "Circuit.h"

#import "MongoID.h"

@interface Circuit()
@property (nonatomic, assign) CircuitInternal *internal;
@property (nonatomic) NSArray *tests;
@end
@implementation Circuit


#pragma mark - Initialisation
static NSValue *valueForGate(CircuitProcess *process) {
    return [NSValue valueWithPointer:process];
}

static NSDictionary *processesById;

- (id) init {
    if ((self = [super init])){
        _internal = CircuitCreate();
    }
    return self;
}

- (void) dealloc {
    CircuitInternal *internal = _internal;
    _internal = nil;
    CircuitDestroy(internal);
}

+ (void) initialize {
    processesById = @{
                      @"in": valueForGate(&CircuitProcessIn),
                      @"out": valueForGate(&CircuitProcessOut),
                      @"button": valueForGate(&CircuitProcessButton),
                      @"light": valueForGate(&CircuitProcessLight),
                      @"or": valueForGate(&CircuitProcessOr),
                      @"not": valueForGate(&CircuitProcessNot),
                      @"nor": valueForGate(&CircuitProcessNor),
                      @"xor": valueForGate(&CircuitProcessXor),
                      @"xnor": valueForGate(&CircuitProcessXnor),
                      @"and": valueForGate(&CircuitProcessAnd),
                      @"nand": valueForGate(&CircuitProcessNand),
                      @"not": valueForGate(&CircuitProcessNot),
                      @"bindec": valueForGate(&CircuitProcessBinDec),
                      @"add8": valueForGate(&CircuitProcessAdd8),
                      @"bin7seg": valueForGate(&CircuitProcessBin7Seg),
                      @"7seg": valueForGate(&CircuitProcess7Seg),
                      @"clock": valueForGate(&CircuitProcessClock)
                      };
}

- (CircuitProcess *) getProcessById:(NSString *)processId {
    CircuitProcess *p;
    id data = [processesById objectForKey:processId];
    if (!data) {
        [NSException raise:@"Could not find object type" format:@"Object type \"%@\" does not exist.", processId, nil];
    }
    p = [data pointerValue];
    return p;
}
- (NSArray *) tests {
    return _tests;
}


- (Circuit *) initWithPackage:(NSDictionary *) package items: (NSArray *) items {
    
    self = [self init];
    NSArray *fields = @[@"name", @"version", @"title", @"author", @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [self setValue:[package valueForKey:key] forKey:key];
    }];

    _viewCenterX = _viewCenterY = 0;
    
    if (package[@"view"]) {
        NSArray *viewCenter = package[@"view"][@"center"];
        if (viewCenter.count >= 2) {
            NSNumber *x = viewCenter[0];
            NSNumber *y = viewCenter[1];
            _viewCenterX = x.floatValue;
            _viewCenterY = y.floatValue;
        }
    }
    
    self.userDescription = package[@"description"];
    
    if ([package valueForKey:@"_id"]) {
        _id = [MongoID idWithString:[package valueForKey:@"_id"]];
    } else {
        _id = [MongoID id];
    }

    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *type = [obj valueForKey:@"type"];
        CircuitProcess *process = [self getProcessById: type];
        CircuitObject *o = CircuitObjectCreate(_internal, process);
        o->id = [MongoID idWithString:[obj valueForKey:@"_id"]];
    }];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ObjectID objId = [MongoID idWithString:[obj valueForKey:@"_id"]];
        CircuitObject *o = CircuitObjectFindById(_internal, objId);
        
        const char * utf8String = [obj[@"name"] UTF8String];
        for(int i = 0; i < 4; i++) {
            o->name[i] = utf8String[i];
            if (utf8String[i] == 0) {
                break;
            }
        }
        o->in  = [[obj valueForKey:@"in"]  intValue];
        o->out = [[obj valueForKey:@"out"] intValue];
        
        NSArray *outputs = [obj objectForKey:@"outputs"];
        [outputs enumerateObjectsUsingBlock:^(id obj, NSUInteger sourceIndex, BOOL *stop) {
            [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger index2, BOOL *stop) {
                // obj === [targetId, n]
                // targetId is the object to which the link connects.
                // It connects into the nth input on that gate.
                ObjectID targetId = [MongoID idWithString:[obj objectAtIndex:0]];
                int targetIndex = [[obj objectAtIndex:1] intValue];
                CircuitObject *target = CircuitObjectFindById(_internal, targetId);
                CircuitLinkCreate(_internal, o, (int)sourceIndex, target, targetIndex);
            }];
        }];
        
        // set position:
        NSArray *pos = [obj valueForKey:@"pos"];
        for(int i = 0; i < 3; i++) {
            o->pos.v[i] = [[pos objectAtIndex:i] floatValue];
        }
    }];
    
    if (package[@"tests"]) {
        Circuit * _self = self;
        NSArray *tests = package[@"tests"];
        NSMutableArray *circuitTests = [NSMutableArray arrayWithCapacity:tests.count];
        [tests enumerateObjectsUsingBlock:^(NSDictionary *testObj, NSUInteger idx, BOOL *stop) {
        
            NSArray * inputIds = testObj[@"inputs"];
            NSArray * outputIds = testObj[@"outputs"];
            
            NSMutableArray *inputNodes = [NSMutableArray arrayWithCapacity:inputIds.count];
            [inputIds enumerateObjectsUsingBlock:^(NSString *objectId, NSUInteger idx, BOOL *stop) {
                CircuitObject *object = [_self findObjectById:objectId];
                [inputNodes addObject:[NSValue valueWithPointer:object]];
            }];
            
            NSMutableArray *outputNodes = [NSMutableArray arrayWithCapacity:outputIds.count];
            [outputIds enumerateObjectsUsingBlock:^(NSString *objectId, NSUInteger idx, BOOL *stop) {
                CircuitObject *object = [_self findObjectById:objectId];
                [outputNodes addObject:[NSValue valueWithPointer:object]];
            }];
            
            [circuitTests addObject:[[CircuitTest alloc]  initWithName:testObj[@"name"] inputs:inputNodes outputs:outputNodes spec:testObj[@"spec"]]];
        }];
        
        _tests = circuitTests;
    }
    
    if (package[@"meta"]) {
        _meta = [package[@"meta"] mutableCopy];
    }
    
    return self;

}

#pragma mark - accessors

- (void)enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = 0 ; i < _internal->objects_count; i++) {
        if (_internal->objects[i].type == NULL) continue;
        block(&_internal->objects[i], &stop);
        if (stop) break;
    }
}

- (void) enumerateObjectsInReverseUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    int count = _internal->objects_count;
    CircuitObject *objects = _internal->objects;
    for(int i = count - 1 ; i >= 0; i--) {
        if (objects[i].type == NULL) continue;
        block(&objects[i], &stop);
        if (stop) break;
    }
}

- (void)enumerateClocksUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    int count = _internal->clocks_count;
    for(int i = 0 ; i < count; i++) {
        if (_internal->clocks[i] == NULL) continue;
        block(_internal->clocks[i], &stop);
        if (stop) break;
    }
}

- (CircuitObject *) findObjectById:(NSString *)searchObjectIdString {
    return CircuitObjectFindById(_internal, [MongoID idWithString:searchObjectIdString]);
}

#pragma mark - simulation
- (int) simulate: (int) ticks {
    return CircuitSimulate(_internal, ticks);
}

- (void) performWriteBlock:(void (^)(CircuitInternal *internal)) block {
    block(_internal);
}

- (void) performBlock:(void (^)(CircuitInternal *object)) block {
    
}

@end
