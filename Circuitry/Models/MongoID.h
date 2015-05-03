#import "MongoIDType.h"

@interface MongoID : NSObject
+ (ObjectID) id;

+ (NSString *) stringWithId: (ObjectID) _id;
+ (ObjectID) idWithString:(NSString *) string;
@end
