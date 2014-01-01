#import <Foundation/Foundation.h>

struct CircuitObject;
typedef struct CircuitObject CircuitObject;

struct CircuitObject {
    int id;
    int in;
    int out;
    int type;
    
    float x;
    float y;
    float z;
    
    char *name;
    CircuitObject ** outputs;
};

@interface Circuit : NSObject

@property NSString *name;
@property NSString *version;
@property NSString *description;
@property NSString *author;
@property NSMutableArray *engines;
@property NSString *license;
@property NSMutableDictionary *dependencies;

@property(readonly) int numItems;
@property CircuitObject *items;

+(Circuit *) circuitWithStream:(NSInputStream *) stream;

@end
