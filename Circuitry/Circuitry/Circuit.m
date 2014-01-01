#import "Circuit.h"


@interface Circuit()

@property CircuitObject **needsUpdate;
@property int needsUpdateCount;
@property int needsUpdateSize;
@property int itemsSize;
@end
@implementation Circuit
- (id) init {
    if ((self = [super init])){
        _needsUpdateCount = 0;
        _needsUpdateSize = 10000;
        _needsUpdate = malloc(sizeof(void *) * _needsUpdateSize);
    }
    return self;
}

void needsUpdate(Circuit *c, CircuitObject *object) {
    c->_needsUpdateCount++;
    if (c->_needsUpdateCount > c->_needsUpdateSize) {
        c->_needsUpdateSize *= 2;
        realloc(c.needsUpdate, sizeof(void *) * c->_needsUpdateSize);
    }
    c.needsUpdate[c->_needsUpdateCount - 1] = object;
}

CircuitObject * addItem(Circuit *c) {
    c->_numItems++;
    
    if (c->_numItems > c->_itemsSize) {
        c->_itemsSize *= 2;
        realloc(c.items, sizeof(void *) * c->_itemsSize);
    }
    
    CircuitObject * object = &c.items[c->_numItems - 1];
    
    needsUpdate(c, object);
    
    return object;
}

+(Circuit *) circuitWithStream:(NSInputStream *) stream {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    
    return [Circuit circuitWithObject: object];
}

+(Circuit *) circuitWithJSON:(NSData *) data {
    NSError *err;
    
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) [NSException exceptionWithName:err.localizedDescription reason:err.localizedFailureReason userInfo:@{}];
    return [Circuit circuitWithObject:object];
}

+ (Circuit *) circuitWithObject: (id) object {
    Circuit *c = [[Circuit alloc] init];
    
    NSArray *fields = @[@"name", @"version", @"description", @"author",  @"license"];
    [fields enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [c setValue:[object objectForKey:key] forKey:key];
    }];

    return c;
}

@end
