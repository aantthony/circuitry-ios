#import <Foundation/Foundation.h>

struct CircuitObject;
typedef struct CircuitObject CircuitObject;
typedef struct CircuitProcess CircuitProcess;
typedef struct CircuitLink CircuitLink;

struct CircuitProcess {
    const char *id;
    int numInputs;
    int numOutputs;
    int (*calculate)(int);
};

struct CircuitLink {
    CircuitLink *nextSibling;
    int sourceIndex;
    int targetIndex;
    CircuitObject *source;
    CircuitObject *target;
};

struct CircuitObject {
    int id;
    int in;
    int out;
    CircuitProcess *type;
    
    union { struct {float x, y, z;}; struct {float v[3];}; } pos;
    
    char *name;
    CircuitLink **outputs;
    CircuitLink **inputs;
};

@interface Circuit : NSObject

@property NSString *name;
@property NSString *version;
@property NSString *description;
@property NSString *author;
@property NSMutableArray *engines;
@property NSString *license;
@property NSMutableDictionary *dependencies;

- (NSData *) toJSON;
+ (Circuit *) circuitWithJSON:(NSData *) data;
- (NSDictionary *) toDictionary;
+ (Circuit *) circuitWithStream:(NSInputStream *) stream;
- (Circuit *) initWithDictionary: (NSDictionary *) dictionary;

- (CircuitProcess *) getProcessById:(NSString *)_id;

- (void) didUpdateObject:(CircuitObject *)object outlet:(int) sourceIndex;
- (void) didUpdateObject:(CircuitObject *)object;
- (void) didUpdateLinks:(CircuitLink *) link;

- (CircuitLink *) addLink:(CircuitObject *)object index: (int)sourceIndex to:(CircuitObject *)target index:(int)targetIndex;
- (void) removeLink:(CircuitLink *)link;

- (CircuitObject *) addObject: (CircuitProcess*) process;
- (void) removeObject:(CircuitObject *) object;

- (int) simulate: (int) ticks;

- (void) enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;
- (void) enumerateObjectsInReverseUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;

@end
