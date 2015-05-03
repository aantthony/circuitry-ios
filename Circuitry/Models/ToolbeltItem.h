//
//  ToolbeltItem.h
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@interface ToolbeltItem : NSObject
- (instancetype) initWithType:(NSString *) type level:(NSUInteger)level image:(UIImage *)image name:(NSString *)name fullName:(NSString *)fullName  subtitle:(NSString *) subtitle;
+ (NSArray *) all;
+ (NSArray *) unlockedGatesForProblemSetProblemInfo:(NSUInteger) problemIndex;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSUInteger level;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic) BOOL isAvailable;
@end
