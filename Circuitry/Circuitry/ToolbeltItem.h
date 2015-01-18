//
//  ToolbeltItem.h
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

@interface ToolbeltItem : NSObject
- (instancetype) initWithType:(NSString *) type image:(UIImage *)image name:(NSString *)name subtitle:(NSString *) subtitle;

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *subtitle;
@end
