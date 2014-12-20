#import <Foundation/Foundation.h>
#import "MongoID.h"
#import "CircuitTest.h"

struct CircuitObject;
typedef struct CircuitObject CircuitObject;
typedef struct CircuitProcess CircuitProcess;
typedef struct CircuitLink CircuitLink;

struct CircuitProcess {
    const char *id;
    int numInputs;
    int numOutputs;
    int (*calculate)(int, void*);
};

struct CircuitLink {
    CircuitLink *nextSibling;
    int sourceIndex;
    int targetIndex;
    CircuitObject *source;
    CircuitObject *target;
};

struct CircuitObject {
    ObjectID id;
    int in;
    int out;
    CircuitProcess *type;
    void *data;
    
    union { struct {float x, y, z;}; struct {float v[3];}; } pos;
    
    char name[4];
    CircuitLink **outputs;
    CircuitLink **inputs;
};

@interface Circuit : NSObject

@property(nonatomic, readonly) ObjectID id;
@property(nonatomic) NSString *name;
@property(nonatomic) NSString *version;
@property(nonatomic) NSString *userDescription;
@property(nonatomic) NSString *title;
@property(nonatomic) NSString *author;
@property(nonatomic) NSMutableArray *engines;
@property(nonatomic) NSString *license;
@property(nonatomic) NSMutableDictionary *dependencies;
@property(nonatomic) NSMutableDictionary *meta;
@property(nonatomic) NSURL *problemSet;
@property(nonatomic) NSNumber *problemSetNumber;

- (NSArray *) tests;

- (NSData *) toJSON;
- (NSDictionary *) exportPackageDictionaryWithoutItems;
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

- (void) enumerateClocksUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;

- (CircuitObject *) findObjectById:(NSString *)_id;

- (Circuit *) initWithPackage:(NSDictionary *) package items: (NSArray *) items;

@end
