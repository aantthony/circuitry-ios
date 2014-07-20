#import "Circuit.h"

#import "MongoID.h"

@interface Circuit()
@property (nonatomic) CircuitObject **needsUpdate;
@property (nonatomic) CircuitObject **needsUpdate2;
@property (nonatomic) CircuitLink   *links;

@property (nonatomic) int clocksSize;
@property (nonatomic) int clocksCount;
@property (nonatomic) CircuitObject **clocks;

@property (nonatomic) int needsUpdateCount;
@property (nonatomic) int needsUpdateSize;
@property (nonatomic) int itemsSize;
@property (nonatomic) int linksSize;
@property (nonatomic) int linksCount;

@property (nonatomic, readonly) int itemsCount;
@property (nonatomic) CircuitObject *items;
@property (nonatomic) NSArray *tests;

@end
@implementation Circuit

void *smalloc(size_t c) {
    return malloc(c);
}
void *scalloc(size_t c, size_t b) {
    return calloc(c, b);
}

void *srealloc(void * d, size_t c) {
    return realloc(d, c);
}



static int XOR  (int x, void *d) { return x == 1 || x == 2;}
static int XNOR (int x, void *d) { return x == 0 || x == 3;}
static int AND  (int x, void *d) { return x == 3;}
static int NAND (int x, void *d) { return x != 3;}
static int NOT  (int x, void *d) { return !x; }
static int NOR  (int x, void *d) { return !x; }
static int OR   (int x, void *d) { return !!x; }
static int ADD8 (int x, void *d) { return (x&255) + (x >> 8); }

static int BINDEC (int x, void *d) { return 1 << x; }
static int BIN7SEG(int x, void *d) {
    switch(x) {
        case 0: return 0b0111111;
        case 1: return 0b0000110;
        case 2: return 0b1011011;
        case 3: return 0b1001111;
        case 4: return 0b1100110;
        case 5: return 0b1101101;
        case 6: return 0b1111101;
        case 7: return 0b0000111;
        case 8: return 0b1111111;
        case 9: return 0b1101111;
        case 10: return 0b1110111;
        case 11: return 0b1111100;
        case 12: return 0b1011000;
        case 13: return 0b1011110;
        case 14: return 0b1111001;
        case 15: return 0b1110001;
            
        default: return 0;
    }
}

static CircuitProcess GateIn = {"in",  0, 1, NULL };
static CircuitProcess GateOut = {"out",  1, 0, NULL };
static CircuitProcess GateButton = {"button",  0, 1, NULL };
static CircuitProcess GateLight = {"light",  1, 0, NULL };
static CircuitProcess GateOr = {"or",  2, 1, OR };
static CircuitProcess GateNot = {"not",  1, 1, NOT };
static CircuitProcess GateNor = {"nor",  2, 1, NOR };
static CircuitProcess GateXor = {"xor",  2, 1, XOR };
static CircuitProcess GateXnor = {"xnor",  2, 1, XNOR };
static CircuitProcess GateAnd = {"and",  2, 1, AND };
static CircuitProcess GateNand = {"nand",  2, 1, NAND };
static CircuitProcess GateBinDec = {"bindec", 4, 16, BINDEC };
static CircuitProcess GateAdd8 = {"add8",  16, 9, ADD8 };
static CircuitProcess GateBin7Seg = {"bin7seg",  4, 7, BIN7SEG };
static CircuitProcess Gate7Seg = {"7seg",  7, 0, NULL };
static CircuitProcess GateClock = {"clock",  0, 1, NULL };

#pragma mark - Initialisation
static NSValue *valueForGate(CircuitProcess *process) {
    return [NSValue valueWithPointer:process];
}

static NSDictionary *processesById;

- (id) init {
    if ((self = [super init])){
        _needsUpdateCount = 0;
        _needsUpdateSize = 100000;
        _needsUpdate  = smalloc(sizeof(CircuitObject *) * _needsUpdateSize);
        _needsUpdate2 = smalloc(sizeof(CircuitObject *) * _needsUpdateSize);
        
        _itemsCount = 0;
        _itemsSize = 100000;
        _items = smalloc((sizeof(CircuitObject) * _itemsSize));
        
        _linksCount = 0;
        _linksSize = 100000;
        _links = smalloc((sizeof(CircuitLink) * _linksSize));
        
        _clocksCount = 0;
        _clocksSize = 512;
        _clocks = smalloc(sizeof(CircuitObject *) * _clocksSize);
    }
    return self;
}
+ (void) initialize {
    processesById = @{
                      @"in": valueForGate(&GateIn),
                      @"out": valueForGate(&GateOut),
                      @"button": valueForGate(&GateButton),
                      @"light": valueForGate(&GateLight),
                      @"or": valueForGate(&GateOr),
                      @"not": valueForGate(&GateNot),
                      @"nor": valueForGate(&GateNor),
                      @"xor": valueForGate(&GateXor),
                      @"xnor": valueForGate(&GateXnor),
                      @"and": valueForGate(&GateAnd),
                      @"nand": valueForGate(&GateNand),
                      @"not": valueForGate(&GateNot),
                      @"bindec": valueForGate(&GateBinDec),
                      @"add8": valueForGate(&GateAdd8),
                      @"bin7seg": valueForGate(&GateBin7Seg),
                      @"7seg": valueForGate(&Gate7Seg),
                      @"clock": valueForGate(&GateClock)
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

#pragma mark - Simulation (written in C)


static CircuitObject *getObjectById(Circuit *c, ObjectID id) {
    for(int i = 0 ; i < c->_itemsCount; i++) {
        CircuitObject *o = &c->_items[i];
        if (o->id.m[0] == id.m[0] && o->id.m[1] == id.m[1] && o->id.m[2] == id.m[2]) return o;
    }
    return NULL;
}

// Queue a gate for a re-calculation
static void needsUpdate(Circuit *c, CircuitObject *object) {
    for(int i = 0; i < c->_needsUpdateCount; i++) {
        if (c->_needsUpdate[i] == object) return;
    }
    c->_needsUpdateCount++;
    if (c->_needsUpdateCount > c->_needsUpdateSize) {
        // dynamically increase array size:
        c->_needsUpdateSize *= 2;
        realloc(&c->_needsUpdate,  sizeof(void *) * c->_needsUpdateSize);
        realloc(&c->_needsUpdate2, sizeof(void *) * c->_needsUpdateSize);
    }
    c.needsUpdate[c->_needsUpdateCount - 1] = object;
}

// Queue a link for a re-calculation (i.e, queue the links targets for recalculation)
static void linksNeedsUpdate(Circuit *c, CircuitLink * link) {
    while(link) {
        needsUpdate(c, link->target);
        link = link->nextSibling;
    }
}

// Create a new circuit object (and queue it for recalculation)
CircuitObject * addObject(Circuit *c, CircuitProcess *type) {

    c->_itemsCount++;
    
    if (c->_itemsCount > c->_itemsSize) {
        c->_itemsSize *= 2;
        srealloc(&c->_items, sizeof(CircuitObject) * c->_itemsSize);
    }
    
    CircuitObject * o = &c->_items[c->_itemsCount - 1];
    
    o->in = 0;
    o->out = 0;
    o->type = type;
    o->pos.x = o->pos.y = o->pos.z = 0.0;
    o->name[0] = '\0';
    o->outputs = scalloc(o->type->numOutputs + o->type->numInputs, sizeof(CircuitLink *));
    o->inputs = o->outputs + o->type->numOutputs;
    
    if (type == &GateClock) {
        c->_clocks[c->_clocksCount++] = o;
    }
    
    needsUpdate(c, o);
    
    return o;
}

// Remove a circuit object (and the links into and out of it)
// Automatically queues the outlet links targets for recalculation
static void removeObject(Circuit *c, CircuitObject *o) {
    for(int i = 0; i < o->type->numOutputs; i++) {
        while(o->outputs[i]) {
            removeLink(c, o->outputs[i]);
        }
    }
    for(int i = 0; i < o->type->numInputs; i++) {
        if (o->inputs[i]) {
            removeLink(c, o->inputs[i]);
        }
    }
    
    free(o->outputs);
    o->outputs = NULL;
    o->type = NULL;
    // TODO: we need to know the index of _items for this:
    // TODO: move the last object in _items to the the position of this object, and then fix all points to that last one
}


static CircuitLink *makeLink(Circuit *c) {
    
    c->_linksCount++;
    
    if (c->_linksCount > c->_linksSize) {
        c->_linksSize *= 2;
        srealloc(&c->_links, sizeof(CircuitLink) * c->_linksSize);
    }
    
    CircuitLink *link = &c->_links[c->_linksCount - 1];
    link->nextSibling = NULL;
    link->sourceIndex = -1;
    link->targetIndex = -1;
    return link;
}

// Remove a link from the circuit, and queue its target for recalculation
static void removeLink(Circuit *c, CircuitLink *link) {
    if (link->target->in & 1<<link->targetIndex) {
        needsUpdate(c, link->target);
    }
    CircuitLink *prevSibling = link->source->outputs[link->sourceIndex];
    if (prevSibling == link) {
        prevSibling = NULL;
        link->source->outputs[link->sourceIndex] = link->nextSibling;
    } else {
        while(prevSibling) {
            if (prevSibling->nextSibling == link) break;
            prevSibling = prevSibling->nextSibling;
        }
        prevSibling->nextSibling = link->nextSibling;
    }
    
    if (link->target) {
        link->target->inputs[link->targetIndex] = NULL;
    }
    
    
    int mask = 1 << link->targetIndex;
    int oldIn = link->target->in;
    if (oldIn & mask) {
        link->target->in = oldIn & ~mask;
        needsUpdate(c, link->target);
    }
    
    memset(link, 0, sizeof(CircuitLink));
    // TODO: we need to know the index of _items for this:
    // TODO: instead of the memset, move the last link in _links to the the position of this object
}

// Add a link to the circuit (and will queue the targets recalculation if necessary). *All* links have a target. The half-made links in the Viewport are fakes.
static CircuitLink *addLink(Circuit *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex) {
    CircuitLink *prev = object->outputs[index];
    CircuitLink *link;

    // For debugging. Really the Objective C code should be separate.
    if (index >= object->type->numOutputs) {
        [NSException raise:@"Invalid Link" format:@"Attempted to create link from outlet #%d, but there are only %d outlets for \"%s\" objects.", index, object->type->numOutputs, object->type->id
         ];
    }
    if (targetIndex >= target->type->numInputs) {
        [NSException raise:@"Invalid Link" format:@"Attempted to create link to inlet #%d, but the object only has #%d inlets", targetIndex, target->type->numInputs];
    }
    if (target->inputs[targetIndex] != NULL) {
        [NSException raise:@"Invalid Link" format:@"Attempted to create link to inlet #%d, but there is already an attachment there", targetIndex];
    }
    
    if (!prev) {
        link = object->outputs[index] = makeLink(c);
    } else {
        while (prev->nextSibling && (prev = prev->nextSibling)) {}
        link = prev->nextSibling = makeLink(c);
    }
    link->source = object;
    link->target = target;
    link->sourceIndex = index;
    link->targetIndex = targetIndex;
    link->target->inputs[targetIndex] = link;
    
    // set value
    
    int mask = 1 << link->targetIndex;
    int oldIn = link->target->in;
    int oldBit = !!(oldIn & mask);
    int curIn = !!(link->source->out & 1 <<link->sourceIndex);
    if (!oldBit && curIn) {
        // it was turned on
        link->target->in = oldIn | mask;
        needsUpdate(c, link->target);
    } else if (oldBit && !curIn) {
        // it was turned off
        link->target->in = oldIn & ~mask;
        needsUpdate(c, link->target);
    } // otherwise it didn't change at all (and so no recalculations are required)
    
    return link;
}

/*
 Logic circuit simulation
 
 - How it works
 
    Each Circuit object maintains a double buffer (which is swapped every "tick") which is a list of gates which have been queued for re-calculation (calculating inputs based on outputs)
    The simulation will first do the recalcution, nulling out the buffer for gates which have not changed.
    Then it goes through that buffer again, skipping the nulls, and copies the ouputs to the connected gates, and queues them back into the loop if their inputs have changed. So it's an event loop.
    This continues until the number of ticks reaches the `ticks` argument.
 
    Return value: number of gates changed
 */
 
static int simulate(Circuit *c, int ticks) {
    int nAffected = 0;
    for(int i = 0; i < ticks; i++) {
        
        int updatingCount = c->_needsUpdateCount;
        if (!updatingCount) return nAffected;
        nAffected += updatingCount;
        CircuitObject **updating = c->_needsUpdate;
        
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            int oldOut = o->out;
            if (o->type == NULL) {
                // was deleted
                updating[i] = NULL;
                continue;
            }
            if (o->type->calculate == NULL) {
                // this doesn't actually need to be updated
//                updating[i] = NULL;
                continue;
            }
            int newOut = o->type->calculate(o->in, o->data);
            // printf("     %s: gate with input: 0x%x  =  0x%x\n", o->type->id, o->in, o->out);
            if (oldOut != newOut) {
                o->out = newOut;
            } else {
                updating[i] = NULL;
            }
        }
        
        c->_needsUpdate = c->_needsUpdate2;
        c->_needsUpdateCount = 0;
        
        // copy outputs of the recently recalculated gates to the inputs of those connected
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            if (!o) continue;
            // printf("Copying output from %s gate 0x%x\n", o->type->id, o->out);
            int newOut = o->out;

            int jm = o->type->numOutputs;
            for(int j = 0; j < jm; j++) {
                int p = 1 << j;
                //int a = p & newOut, b = p & oldOut;
                //if (a != b) linksNeedsUpdate(c, o->outputs[j]);
                
                int a = !!(p & newOut);
                // printf("Outlet %d, place %d\n", j, a);
                CircuitLink *link = o->outputs[j];
                while(link) {
                    // printf("Write %d to %s gate\n", a, link->target->type->id);
                    int oldIn = link->target->in;
                    int mask = 1 << link->targetIndex;
                    int oldBit = !!(oldIn & mask);
                    if (oldBit != a) {
                        link->target->in = oldIn & ~ mask;
                        if (a) link->target->in |= mask;
                        // printf("Now that %s gate has input 0x%x\n", link->target->type->id, link->target->in);
                        needsUpdate(c, link->target);
                    } else break;
                    link = link->nextSibling;
                }
            }
        }
        
        c->_needsUpdate2 = updating;
    }
    return nAffected;
}

#pragma mark - Loading

// Load a circuit from a JSON stream. (not ideal since NSJSONSerialization will still store the whole NSDictioanry in memory, but for now it is fine)
+ (Circuit *) circuitWithStream:(NSInputStream *) stream {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    return [[Circuit alloc] initWithDictionary:object];
}

// Load a circuit from a utf8 json string
+ (Circuit *) circuitWithJSON:(NSData *) data {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) [[NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}] raise];
    return [[Circuit alloc] initWithDictionary:object];
}

- (NSDictionary *) toDictionary {

    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:_itemsCount];
    [self enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        
        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:object->type->numOutputs];
        for(int i = 0; i < object->type->numOutputs; i++) {
            NSMutableArray *linksFromOutlet = [NSMutableArray array];
            CircuitLink *link = object->outputs[i];
            while (link) {
                [linksFromOutlet addObject:@[[MongoID stringWithId:link->target->id], @(link->targetIndex)]];
                link = link->nextSibling;
            }
            [outputs addObject:linksFromOutlet];
        }
//        
//        NSLog(@"%@",[NSString stringWithUTF8String:object->type->id]);
//        NSLog(@"%@",@(object->id));
//        NSLog(@"%@",@[@(object->pos.x), @(object->pos.y), @(object->pos.z)]);
//        NSLog(@"%@",object->name ? [NSString stringWithUTF8String:object->name] : @"");
//        NSLog(@"%@",@(object->in));
//        NSLog(@"%@",@(object->out));
//        NSLog(@"%@",outputs);
        
        NSString *name = nil;
        if (object->name) {
            name = [NSString stringWithUTF8String:object->name];
        }
        [items addObject:@{
                           @"type": [NSString stringWithUTF8String:object->type->id],
                           @"_id": [MongoID stringWithId:object->id],
                           @"pos": @[@(object->pos.x), @(object->pos.y), @(object->pos.z)],
                           @"name": name ? name : @"",
                           @"in": @(object->in),
                           @"out": @(object->out),
                           @"outputs": outputs
                           }];
    }];
    return @{
             @"_id": [MongoID stringWithId:_id],
             @"name": _name,
             @"version": _version,
             @"description": _userDescription,
             @"title": _title,
             @"author": _author,
             @"license": _license,
             @"items": items
             };
}

// Serialize
- (NSData *) toJSON {
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:&err];
    
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    return data;
}

- (NSArray *) tests {
    return _tests;
}

- (NSDictionary *) metadata {
    NSMutableArray *testsArray = [NSMutableArray arrayWithCapacity:_tests.count];
    [_tests enumerateObjectsUsingBlock:^(CircuitTest *test, NSUInteger idx, BOOL *stop) {
        [testsArray addObject:@{
                                @"name": test.name,
                                @"inputs": test.inputIds,
                                @"outputs": test.outputIds,
                                @"spec": test.spec
                                }];
    }];
    
    return @{
             @"_id": [MongoID stringWithId:_id],
             @"name": _name,
             @"version": _version,
             @"description": _userDescription,
             @"title": _title,
             @"author": _author,
             @"license": _license,
             @"engines": @{@"circuitry": @">=0.0"},
             @"tests" : testsArray
             };
    
}


- (Circuit *) initWithPackage:(NSDictionary *) package items: (NSArray *) items {
    
    self = [self init];
    NSArray *fields = @[@"name", @"version", @"title", @"author",  @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [self setValue:[package valueForKey:key] forKey:key];
    }];
    
    self.userDescription = package[@"description"];
    
    if ([package valueForKey:@"_id"]) {
        _id = [MongoID idWithString:[package valueForKey:@"_id"]];
    } else {
        _id = [MongoID id];
    }

    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *type = [obj valueForKey:@"type"];
        CircuitProcess *process = [self getProcessById: type];
        CircuitObject *o = addObject(self, process);
        o->id = [MongoID idWithString:[obj valueForKey:@"_id"]];
    }];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *o = getObjectById(self, [MongoID idWithString:[obj valueForKey:@"_id"]]);
        
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
                CircuitObject *target = getObjectById(self, targetId);
                addLink(self, o, sourceIndex, target, targetIndex);
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
    
    return self;

}

- (Circuit *) initWithDictionary: (id) object {
    return [self initWithPackage:object items: object[@"items"]];
}


#pragma mark - accessors

- (void)enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = 0 ; i < _itemsCount; i++) {
        if (_items[i].type == NULL) continue;
        block(&_items[i], &stop);
        if (stop) break;
    }
}
- (void) enumerateObjectsInReverseUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = _itemsCount - 1 ; i >= 0; i--) {
        if (_items[i].type == NULL) continue;
        block(&_items[i], &stop);
        if (stop) break;
    }
}


- (void)enumerateClocksUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = 0 ; i < _clocksCount; i++) {
        if (_clocks[i] == NULL) continue;
        block(_clocks[i], &stop);
        if (stop) break;
    }
}

- (CircuitObject *) findObjectById:(NSString *)searchObjectIdString {
    ObjectID searchId = [MongoID idWithString:searchObjectIdString];
    
    for(int i = _itemsCount - 1 ; i >= 0; i--) {
        if (_items[i].type == NULL) continue;
        ObjectID *objId = &_items[i].id;
        if (objId->m[2] == searchId.m[2] && objId->m[0] == searchId.m[0] && objId->m[1] == searchId.m[1]) {
            return &_items[i];
        }
    }
    
    return nil;
}

#pragma mark - circuit modification

- (CircuitObject *) addObject: (CircuitProcess*) process {
    CircuitObject *o = addObject(self, process);
    o->id  = [MongoID id];
    
    return o;
}

- (void) removeObject:(CircuitObject *) object {
    removeObject(self, object);
}

- (void) removeLink:(CircuitLink *)link {
    removeLink(self, link);
}

- (CircuitLink *) addLink:(CircuitObject *)object index: (int)sourceIndex to:(CircuitObject *)target index:(int)targetIndex {
    return addLink(self, object, sourceIndex, target, targetIndex);
}



#pragma mark - circuit object and link modification notification

// Add items to the event queue: This needs to be called when an object is modified externally
- (void) didUpdateObject:(CircuitObject *)object {
    needsUpdate(self, object);
}

// Add items to the event queue: This needs to be called when an objects output state is modified externally, but didUpdateObject is not called.
// It is possible to just always call didUpdateObject, but this can be more efficent if you can be sure that only certain known links will change.
- (void) didUpdateObject:(CircuitObject *)object outlet:(int) sourceIndex {
    linksNeedsUpdate(self, object->outputs[sourceIndex]);
}

// Does the same thing as didUpdateObject: outlet:
- (void) didUpdateLinks:(CircuitLink *) link {
    linksNeedsUpdate(self, link);
}

#pragma mark - simulation
- (int) simulate: (int) ticks {
    return simulate(self, ticks);
}

@end
