#import <Foundation/Foundation.h>
#import "MongoID.h"
#import "CircuitTest.h"

#import "CircuitInternal.h"

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

@property(nonatomic) NSDictionary * viewDetails;
@property(nonatomic) float viewCenterX;
@property(nonatomic) float viewCenterY;

- (NSArray *) tests;

- (CircuitProcess *) getProcessById:(NSString *)_id;

- (int) simulate: (int) ticks;

- (void) enumerateObjectsUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;
- (void) enumerateObjectsInReverseUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;

- (void) enumerateClocksUsingBlock:(void (^)(CircuitObject *object, BOOL *stop))block;

- (CircuitObject *) findObjectById:(NSString *)_id;

- (Circuit *) initWithPackage:(NSDictionary *) package items: (NSArray *) items;
- (void) performWriteBlock:(void (^)(CircuitInternal *internal)) block;
@end
