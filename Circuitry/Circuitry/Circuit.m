#import "Circuit.h"

@interface Circuit()
@property CircuitObject **needsUpdate;
@property CircuitObject **needsUpdate2;
@property CircuitLink   *links;
@property int needsUpdateCount;
@property int needsUpdateSize;
@property int itemsSize;
@property int linksSize;
@property int linksCount;

@property(readonly) int itemsCount;
@property CircuitObject *items;
@property NSInteger largestItemID;

@end
@implementation Circuit


void *smalloc(size_t c) {
    NSLog(@"Allocate %0.1f MB\n", c / 1000000.0);
    return malloc(c);
}
void *scalloc(size_t c, size_t b) {
    NSLog(@"Allocate %0.1f MB\n", (c * b) / 1000000.0);
    return calloc(c, b);
}

void *srealloc(void * d, size_t c) {
    NSLog(@"ReAllocate %0.1f MB\n", c / 1000000.0);
    return realloc(d, c);
}



int XOR  (int x) { return x == 1 || x == 2;}
int XNOR (int x) { return x == 0 || x == 3;}
int AND  (int x) { return x == 3;}
int NAND (int x) { return x != 3;}
int NOT  (int x) { return !x; }
int NOR  (int x) { return !x; }
int OR   (int x) { return !!x; }

CircuitProcess defaultGates[] = {
    {"in",  0, 1, NULL },
    {"out", 1, 0, NULL },
    {"or",  2, 1, OR },
    {"not", 1, 1, NOT },
    {"nor", 2, 1, NOR },
    {"xor", 2, 1, XOR },
    {"xnor", 2, 1, XOR },
    {"and", 2, 1, AND },
    {"nand", 2, 1, NAND },
    {"not", 1, 1, NOT }
};

#pragma mark - Initialisation
NSValue *valueForGate(CircuitProcess *process) {
    return [NSValue valueWithPointer:process];
}

NSDictionary *processesById;

- (id) init {
    if ((self = [super init])){
        _needsUpdateCount = 0;
        _needsUpdateSize = 100000;
        _needsUpdate  = smalloc(sizeof(void *) * _needsUpdateSize);
        _needsUpdate2 = smalloc(sizeof(void *) * _needsUpdateSize);
        
        _itemsCount = 0;
        _itemsSize = 100000;
        _items = smalloc((sizeof(CircuitObject) * _itemsSize));
        _largestItemID = 0;
        
        _linksCount = 0;
        _linksSize = 100000;
        _links = smalloc((sizeof(CircuitLink) * _linksSize));
    }
    return self;
}
+ (void) initialize {
    processesById = @{
                      @"in": valueForGate(&defaultGates[0]),
                      @"out": valueForGate(&defaultGates[1]),
                      @"or": valueForGate(&defaultGates[2]),
                      @"not": valueForGate(&defaultGates[3]),
                      @"nor": valueForGate(&defaultGates[4]),
                      @"xor": valueForGate(&defaultGates[5]),
                      @"xnor": valueForGate(&defaultGates[6]),
                      @"and": valueForGate(&defaultGates[7]),
                      @"nand": valueForGate(&defaultGates[8]),
                      @"not": valueForGate(&defaultGates[9])
                      };
}

- (CircuitProcess *) getProcessById:(NSString *)_id {
    CircuitProcess *p;
    id data = [processesById objectForKey:_id];
    if (!data) [NSException raise:@"Could not find object type" format:@"Object type \"%@\" does not exist.", _id, nil];
    p = [data pointerValue];
    return p;
}

#pragma mark - Simulation (written in C)


CircuitObject *getObjectById(Circuit *c, int id) {
    for(int i = 0 ; i < c->_itemsCount; i++) {
        CircuitObject *o = &c->_items[i];
        if (o->id == id) return o;
    }
    return NULL;
}
void needsUpdate(Circuit *c, CircuitObject *object) {
    for(int i = 0; i < c->_needsUpdateCount; i++) {
        if (c->_needsUpdate[i] == object) return;
    }
    c->_needsUpdateCount++;
    if (c->_needsUpdateCount > c->_needsUpdateSize) {
        c->_needsUpdateSize *= 2;
        realloc(&c->_needsUpdate,  sizeof(void *) * c->_needsUpdateSize);
        realloc(&c->_needsUpdate2, sizeof(void *) * c->_needsUpdateSize);
    }
    c.needsUpdate[c->_needsUpdateCount - 1] = object;
}

void linksNeedsUpdate(Circuit *c, CircuitLink * link) {
    while(link) {
        needsUpdate(c, link->target);
        link = link->nextSibling;
    }
}


CircuitObject * addObject(Circuit *c, CircuitProcess *type) {
    int id = 0;

    c->_itemsCount++;
    
    if (c->_itemsCount > c->_itemsSize) {
        c->_itemsSize *= 2;
        srealloc(&c->_items, sizeof(CircuitObject) * c->_itemsSize);
    }
    
    CircuitObject * o = &c->_items[c->_itemsCount - 1];
    
    o->id = id;
    o->in = 0;
    o->out = 0;
    o->type = type;
    o->pos.x = o->pos.y = o->pos.z = 0.0;
    o->name = "";
    o->outputs = scalloc(o->type->numOutputs + o->type->numInputs, sizeof(CircuitLink *));
    o->inputs = o->outputs + o->type->numOutputs;
    
    needsUpdate(c, o);
    
    return o;
}

void removeObject(Circuit *c, CircuitObject *o) {
    for(int i = 0; i < o->type->numOutputs; i++) {
        while(o->outputs[i]) {
            removeLink(c, o->outputs[i]);
        }
    }
    for(int i = 0; i < o->type->numInputs; i++) {
        removeLink(c, o->inputs[i]);
    }
    
    free(o->outputs);
}




CircuitLink *makeLink(Circuit *c) {
    
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

void removeLink(Circuit *c, CircuitLink *link) {
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
}

CircuitLink *addLink(Circuit *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex) {
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
        link->target->in = oldIn | mask;
        needsUpdate(c, link->target);
    } else if (oldBit && !curIn) {
        link->target->in = oldIn & ~mask;
        needsUpdate(c, link->target);
    }
    
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
 
int simulate(Circuit *c, int ticks) {
    int nAffected = 0;
    for(int i = 0; i < ticks; i++) {
        int updatingCount = c->_needsUpdateCount;
        if (!updatingCount) return nAffected;
        nAffected += updatingCount;
        CircuitObject **updating = c->_needsUpdate;
        
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            int oldOut = o->out;
            
            if (o->type->calculate == NULL) {
                // this doesn't actually need to be updated
//                updating[i] = NULL;
                continue;
            }
            int newOut = o->type->calculate(o->in);
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

+ (Circuit *) circuitWithStream:(NSInputStream *) stream {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    return [[Circuit alloc] initWithDictionary:object];
}

+ (Circuit *) circuitWithJSON:(NSData *) data {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    return [[Circuit alloc] initWithDictionary:object];
}

- (NSData *) toJSON {
    NSError *err;
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:_itemsCount];
    [self enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {

        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:object->type->numOutputs];
        for(int i = 0; i < object->type->numOutputs; i++) {
            NSMutableArray *linksFromOutlet = [NSMutableArray array];
            CircuitLink *link = object->outputs[i];
            while (link) {
                [linksFromOutlet addObject:@[@(link->target->id), @(link->targetIndex)]];
                link = link->nextSibling;
            }
            [outputs addObject:linksFromOutlet];
        }
        
        [items addObject:@{
                           @"type": [NSString stringWithUTF8String:object->type->id],
                           @"id": @(object->id),
                           @"pos": @[@(object->pos.x), @(object->pos.y), @(object->pos.z)],
                           @"name": object->name ? [NSString stringWithUTF8String:object->name] : @"",
                           @"in": @(object->in),
                           @"out": @(object->out),
                           @"outputs": outputs
                           }];
    }];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{
                                              @"name": _name,
                                              @"version": _version,
                                              @"description": _description,
                                              @"author": _author,
                                              @"license": _license,
                                              @"items": items
                                              } options:0 error:&err];
    
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    return data;
}

- (Circuit *) initWithDictionary: (id) object {
    self = [self init];
    NSArray *fields = @[@"name", @"version", @"description", @"author",  @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [self setValue:[object valueForKey:key] forKey:key];
    }];
    
    NSArray *items = [object objectForKey:@"items"];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *type = [obj valueForKey:@"type"];
        CircuitProcess *process = [self getProcessById: type];
        CircuitObject *o = addObject(self, process);
        o->id  = [[obj valueForKey:@"id"] intValue];
        if (o->id > _largestItemID) {
            _largestItemID = o->id;
        }
    }];
    
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *o = getObjectById(self, [[obj valueForKey:@"id"] intValue]);
        
        o->name = (char *)[[obj valueForKey:@"name"] UTF8String];
        o->in  = [[obj valueForKey:@"in"]  intValue];
        o->out = [[obj valueForKey:@"out"] intValue];
        
        NSArray *outputs = [obj objectForKey:@"outputs"];
        [outputs enumerateObjectsUsingBlock:^(id obj, NSUInteger sourceIndex, BOOL *stop) {
            [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger index2, BOOL *stop) {
                int targetId = [[obj objectAtIndex:0] intValue];
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
    
    return self;
}


#pragma mark - accessors

- (void)enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = 0 ; i < _itemsCount; i++) {
        if (&_items[i] == NULL) continue;
        block(&_items[i], &stop);
        if (stop) break;
    }
}
- (void) enumerateObjectsInReverseUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = _itemsCount - 1 ; i >= 0; i--) {
        if (&_items[i] == NULL) continue;
        block(&_items[i], &stop);
        if (stop) break;
    }
}


#pragma mark - circuit modification

- (CircuitObject *) addObject: (CircuitProcess*) process {
    CircuitObject *o = addObject(self, process);
    o->id  = ++_largestItemID;
    
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

// Add items to the event queue:
- (void) didUpdateObject:(CircuitObject *)object {
    needsUpdate(self, object);
}

- (void) didUpdateObject:(CircuitObject *)object outlet:(int) sourceIndex {
    linksNeedsUpdate(self, object->outputs[sourceIndex]);
}

- (void) didUpdateLinks:(CircuitLink *) link {
    linksNeedsUpdate(self, link);
}


#pragma mark - simulation
- (int) simulate: (int) ticks {
    return simulate(self, ticks);
}

@end
