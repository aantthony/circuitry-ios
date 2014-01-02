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
};

@interface Circuit : NSObject

@property NSString *name;
@property NSString *version;
@property NSString *description;
@property NSString *author;
@property NSMutableArray *engines;
@property NSString *license;
@property NSMutableDictionary *dependencies;

+ (Circuit *) circuitWithStream:(NSInputStream *) stream;
- (Circuit *) initWithObject: (id) object;

- (int) simulate: (int) ticks;

- (void)enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;

@end
