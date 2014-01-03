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


#pragma mark - Initialisation
- (id) init {
    if ((self = [super init])){
        _needsUpdateCount = 0;
        _needsUpdateSize = 100000;
        _needsUpdate  = smalloc(sizeof(void *) * _needsUpdateSize);
        _needsUpdate2 = smalloc(sizeof(void *) * _needsUpdateSize);
        
        _itemsCount = 0;
        _itemsSize = 100000;
        _items = smalloc((sizeof(CircuitObject) * _itemsSize));
        
        _linksCount = 0;
        _linksSize = 100000;
        _links = smalloc((sizeof(CircuitLink) * _linksSize));
    }
    return self;
}

int XOR  (int x) { return x == 1 || x == 2;}
int AND  (int x) { return x == 3;}
int NAND (int x) { return x != 3;}
int NOT  (int x) { return !x; }
int NOR  (int x) { return !x; }
int OR   (int x) { return x; }

CircuitProcess defaultGates[] = {
    {"in",  0, 1, NULL },
    {"out", 1, 0, NULL },
    {"or",  2, 0, OR },
    {"not", 1, 1, NOT },
    {"nor", 2, 1, NOR },
    {"xor", 2, 1, XOR },
    {"and", 2, 1, AND },
    {"nand", 2, 1, NAND }
};

NSValue *valueForGate(CircuitProcess *process) {
    return [NSValue valueWithPointer:process];
}

NSDictionary *processesById;

+ (void) initialize {
    processesById = @{
                      @"in": valueForGate(&defaultGates[0]),
                      @"out": valueForGate(&defaultGates[1]),
                      @"or": valueForGate(&defaultGates[2]),
                      @"not": valueForGate(&defaultGates[3]),
                      @"nor": valueForGate(&defaultGates[4]),
                      @"xor": valueForGate(&defaultGates[5]),
                      @"and": valueForGate(&defaultGates[6]),
                      @"nand": valueForGate(&defaultGates[7])
                      };
}

CircuitProcess *getProcessById(Circuit *c, NSString *_id) {
    CircuitProcess *p;
    id data = [processesById objectForKey:_id];
    if (!data) [NSException raise:@"Could not find object type" format:@"Object type \"%@\" does not exist.", _id, nil];
    p = [data pointerValue];
    NSLog(@"getProcessById: \"%@\" gate has %d outputs...", _id, p->numOutputs);
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

void linkNeedsUpdate(Circuit *c, CircuitObject *object, int sourceIndex) {
    CircuitLink *link = object->outputs[sourceIndex];
    if (!link) return;
    do {
        needsUpdate(c, link->target);
    } while ((link = link->nextSibling));
}

CircuitObject * addItem(Circuit *c, CircuitProcess *type) {
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
    o->outputs = scalloc(o->type->numOutputs, sizeof(CircuitLink *));
    
    needsUpdate(c, o);
    
    return o;
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

CircuitLink *addLink(Circuit *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex) {
    CircuitLink *prev = object->outputs[index];
    CircuitLink *link;
    if (index >= object->type->numOutputs) {
        [NSException raise:@"Invalid Link" format:@"Attempted to create link from outlet #%d, but there are only %d outlets for \"%s\" objects.", index, object->type->numOutputs, object->type->id
         ];
    }
    if (!prev) {
        link = object->outputs[index] = makeLink(c);
    } else {
        while (prev->nextSibling && (prev = prev->nextSibling)) {}
        link = prev->nextSibling = makeLink(c);
    }
    link->target = target;
    link->sourceIndex = index;
    link->targetIndex = targetIndex;
    
    return link;
}

int simulate(Circuit *c, int ticks) {
    int nAffected = 0;
    for(int i = 0; i < ticks; i++) {
        int updatingCount = c->_needsUpdateCount;
        nAffected += updatingCount;
        CircuitObject **updating = c->_needsUpdate;
        c->_needsUpdate = c->_needsUpdate2;
        c->_needsUpdateCount = 0;
        
        for(int i = 0; i < updatingCount; i++) {
            CircuitObject *o = updating[i];
            int oldOut = o->out;
            if (o->type->calculate == NULL) {
                // this doesn't actually need to be updated
                continue;
            }
            int newOut = o->type->calculate(o->in);
            if (oldOut != newOut) {
                
                o->out = newOut;
                int jm = o->type->numOutputs;
                for(int j = 0; j < jm; j++) {
                    int p = 1 << j;
                    int a = p & newOut, b = p & oldOut;
                    if (a != b) linkNeedsUpdate(c, o, j);
                }
            }
        }
        
        c->_needsUpdate2 = updating;
        c->_needsUpdateCount = 0;
    }
    return nAffected;
}

#pragma mark - Loading

+ (Circuit *) circuitWithStream:(NSInputStream *) stream {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    return [[Circuit alloc] initWithObject:object];
}

+ (Circuit *) circuitWithJSON:(NSData *) data {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    return [[Circuit alloc] initWithObject:object];
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

- (Circuit *) initWithObject: (id) object {
    self = [self init];
    NSArray *fields = @[@"name", @"version", @"description", @"author",  @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [self setValue:[object valueForKey:key] forKey:key];
    }];
    
    NSArray *items = [object objectForKey:@"items"];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *type = [obj valueForKey:@"type"];
        CircuitProcess *process = getProcessById(self, type);
        CircuitObject *o = addItem(self, process);
        o->id  = [[obj valueForKey:@"id"] intValue];
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


#pragma mark - public

- (void)enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block {
    BOOL stop = NO;
    for(int i = 0 ; i < _itemsCount; i++) {
        if (&_items[i] == NULL) continue;
        block(&_items[i], &stop);
        if (stop) break;
    }
}

- (int) simulate: (int) ticks {
    return simulate(self, ticks);
}

@end
