#import "Circuit.h"

@interface Circuit()
@property CircuitObject **needsUpdate;
@property CircuitObject **needsUpdate2;
@property int needsUpdateCount;
@property int needsUpdateSize;
@property int itemsSize;
@end
@implementation Circuit

- (id) init {
    if ((self = [super init])){
        _needsUpdateCount = 0;
        _needsUpdateSize = 100000;
        _needsUpdate  = malloc(sizeof(void *) * _needsUpdateSize);
        _needsUpdate2 = malloc(sizeof(void *) * _needsUpdateSize);
        
        _itemsSize = 100000;
        _items = malloc((sizeof(CircuitObject) * _itemsSize));
    }
    return self;
}

int XOR  (int x) { return x == 1 || x == 2;}
int AND  (int x) { return x == 3;}
int NAND (int x) { return x != 3;}
int NOT  (int x) { return !x; }
int NOR  (int x) { return !x; }
int OR   (int x) { return x; }

NSDictionary *processesById;

+ (void) initialize {
    processesById = [[NSDictionary alloc] initWithObjectsAndKeys:
                     [NSValue value:&(CircuitProcess){"or",  2, 1, OR  } withObjCType:@encode(CircuitProcess *)] , @"or",
                     [NSValue value:&(CircuitProcess){"not", 1, 1, NOT } withObjCType:@encode(CircuitProcess *)] , @"not",
                     [NSValue value:&(CircuitProcess){"nor", 2, 1, NOR } withObjCType:@encode(CircuitProcess *)] , @"nor",
                     [NSValue value:&(CircuitProcess){"xor", 2, 1, XOR } withObjCType:@encode(CircuitProcess *)] , @"xor",
                     [NSValue value:&(CircuitProcess){"and", 2, 1, AND } withObjCType:@encode(CircuitProcess *)] , @"and",
                     [NSValue value:&(CircuitProcess){"nand",2, 1, NAND} withObjCType:@encode(CircuitProcess *)] , @"nand",
                     nil];
}

CircuitProcess *getProcessById(Circuit *c, NSString *id) {
    CircuitProcess *p;
    [[processesById objectForKey:id] getValue:&p];
    return p;
}

CircuitObject *getObjectById(Circuit *c, int id) {
    for(int i = 0 ; i < c->_numItems; i++) {
        CircuitObject *o = &c->_items[i];
        if (o->id == id) return o;
    }
    return NULL;
}
void needsUpdate(Circuit *c, CircuitObject *object) {
    c->_needsUpdateCount++;
    if (c->_needsUpdateCount > c->_needsUpdateSize) {
        c->_needsUpdateSize *= 2;
        realloc(c.needsUpdate,  sizeof(void *) * c->_needsUpdateSize);
        realloc(c.needsUpdate2, sizeof(void *) * c->_needsUpdateSize);
    }
    c.needsUpdate[c->_needsUpdateCount - 1] = object;
}

CircuitObject * addItem(Circuit *c) {
    int id = c->_numItems;
    c->_numItems++;
    
    if (c->_numItems > c->_itemsSize) {
        c->_itemsSize *= 2;
        realloc(c.items, sizeof(void *) * c->_itemsSize);
    }
    
    CircuitObject * o = &c.items[id];
    
    o->id = id;
    o->in = 0;
    o->out = 0;
    o->type = NULL;
    o->pos = GLKVector3Make(0.0, 0.0, 0.0);
    o->name = "";
//    o->outputs = malloc(sizeof(CircuitObject *) * );
    
    needsUpdate(c, o);
    
    return o;
}


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

void addLink(Circuit *c, CircuitObject *object, int index, CircuitObject *target, int targetIndex) {
    
}

- (Circuit *) initWithObject: (id) object {
    self = [self init];
    NSArray *fields = @[@"name", @"version", @"description", @"author",  @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [self setValue:[object valueForKey:key] forKey:key];
    }];
    
    NSArray *items = [object objectForKey:@"items"];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CircuitObject *o = addItem(self);
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
        
        NSString *type = [obj valueForKey:@"type"];
        o->type = getProcessById(self, type);
        
        // set position:
        NSArray *pos = [obj valueForKey:@"pos"];
        for(int i = 0; i < 3; i++) {
            o->pos.v[i] = [[pos objectAtIndex:i] floatValue];
        }
    }];
    
    return self;
}

- (void) simulate: (int) ticks {
    for(int i = 0; i < ticks; i++) {
        int _needsUpdate2Count = 0;
        for(int i = 0; i < _needsUpdateCount; i++) {
            CircuitObject *o = &_items[i];
            int oldOut = o->out;
            int newOut = o->type->calculate(o->in);
            if (oldOut != newOut) {
                //            int nOutputs = o->
                //            _needsUpdate2Count++;
            }
        }
        
        if ((_needsUpdateCount = _needsUpdate2Count)) {
            CircuitObject **tmp = _needsUpdate;
            _needsUpdate = _needsUpdate2;
            _needsUpdate2 = tmp;
        }
    }
}

@end
