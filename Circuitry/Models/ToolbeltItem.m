//
//  ToolbeltItem.m
//  Circuitry
//
//  Created by Anthony Foster on 7/07/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import "ToolbeltItem.h"

@implementation ToolbeltItem

- (instancetype) initWithType:(NSString *)type level:(NSUInteger)level image:(UIImage *)image name:(NSString *)name fullName:(NSString *)fullName subtitle:(NSString *)subtitle {
    self = [super init];
    
    _type     = type;
    _level    = level;
    _image    = image;
    _name     = name;
    _fullName = fullName;
    _subtitle = subtitle;
    
    return self;
}

+ (NSArray *) all {
    static NSArray *_all = nil;
    if (_all) return _all;
    _all = @[
             [[ToolbeltItem alloc] initWithType:@"button"  level:0  image:[UIImage imageNamed:@"switch"]   name:@"Button" fullName:@"Switch Button" subtitle:@"Toggle button"],
      // [[ToolbeltItem alloc] initWithType:@"pbtn"    image:[UIImage imageNamed:@"pushbutton"] name:@"Button" subtitle:@"Push button"],
             [[ToolbeltItem alloc] initWithType:@"light"   level:0  image:[UIImage imageNamed:@"led"]      name:@"Light" fullName:@"Light" subtitle:@"Light Emitting Diode"],
             [[ToolbeltItem alloc] initWithType:@"lightg"  level:0  image:[UIImage imageNamed:@"led"]      name:@"Light (Green)" fullName:@"Green Light" subtitle:@"Light Emitting Diode"],
             [[ToolbeltItem alloc] initWithType:@"or"      level:3  image:[UIImage imageNamed:@"or"]       name:@"OR" fullName: @"OR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"and"     level:2  image:[UIImage imageNamed:@"and"]      name:@"AND" fullName:@"AND Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"not"     level:4  image:[UIImage imageNamed:@"not"]      name:@"NOT" fullName: @"NOT Gate" subtitle:@"1 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"xor"     level:5  image:[UIImage imageNamed:@"xor"]      name:@"XOR" fullName:@"XOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"xnor"    level:10  image:[UIImage imageNamed:@"xnor"]     name:@"XNOR" fullName:@"XNOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"nand"    level:4  image:[UIImage imageNamed:@"nand"]     name:@"NAND" fullName:@"NAND Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"nor"     level:10 image:[UIImage imageNamed:@"nor"]      name:@"NOR" fullName:@"NOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"ha"      level:13 image:[UIImage imageNamed:@"ha"]       name:@"Half adder" fullName:@"Half Adder" subtitle:@"2 in, 2 out"],
      [[ToolbeltItem alloc] initWithType:@"fa"      level:14 image:[UIImage imageNamed:@"fa"]       name:@"Full adder" fullName:@"Full Adder" subtitle:@"3 in, 2 out"],
      [[ToolbeltItem alloc] initWithType:@"add4"    level:16 image:[UIImage imageNamed:@"add4"]     name:@"4-bit adder" fullName:@"4-bit adder" subtitle:@"8 in, 4 out"],
      [[ToolbeltItem alloc] initWithType:@"mult4"   level:17 image:[UIImage imageNamed:@"mult4"]    name:@"4-bit multiplier" fullName:@"4-bit multiplier" subtitle:@"8 in, 4 out"],
      [[ToolbeltItem alloc] initWithType:@"add8"    level:16 image:[UIImage imageNamed:@"add8"]     name:@"8-bit adder" fullName:@"8-bit adder" subtitle:@"16 in, 8 out"],
      [[ToolbeltItem alloc] initWithType:@"mult8"   level:17 image:[UIImage imageNamed:@"mult8"]    name:@"8-bit multiplier" fullName:@"8-bit multiplier" subtitle:@"16 in, 8 out"],
      [[ToolbeltItem alloc] initWithType:@"bin7seg" level:18 image:[UIImage imageNamed:@"bin7seg"]  name:@"7seg Decoder" fullName:@"BCD to 7-segment display decoder" subtitle:@"4 bit input, 7 display"],
      [[ToolbeltItem alloc] initWithType:@"7seg"    level:18 image:[UIImage imageNamed:@"7seg"]     name:@"7-Segment Display" fullName:@"7-Segment Display" subtitle:@"Display"],
      [[ToolbeltItem alloc] initWithType:@"7segbin" level:13 image:[UIImage imageNamed:@"7seg"] name:@"Number Display" fullName:@"Number Display with binary input" subtitle:@"Display"],
             
             [[ToolbeltItem alloc] initWithType:@"jk"   level:20  image:[UIImage imageNamed:@"jk"]    name:@"JK flip-flop" fullName:@"JK flip-flop" subtitle:@"clocked"],
             [[ToolbeltItem alloc] initWithType:@"sr"   level:20  image:[UIImage imageNamed:@"sr"]    name:@"SR Latch" fullName:@"SR NOR Latch" subtitle:@"Set, reset, Q"],
             [[ToolbeltItem alloc] initWithType:@"t"   level:20  image:[UIImage imageNamed:@"t"]    name:@"T flip-flop" fullName:@"T flip-flop" subtitle:@"Toggle"],
             [[ToolbeltItem alloc] initWithType:@"d"   level:20  image:[UIImage imageNamed:@"d"]    name:@"D flip-flop" fullName:@"D flip-flop" subtitle:@"Delay"],
      [[ToolbeltItem alloc] initWithType:@"clock"   level:7  image:[UIImage imageNamed:@"clock"]    name:@"Clock" fullName:@"Clock" subtitle:@"Square wave"]
    ];
    return _all;
}

+ (NSArray *) unlockedGatesForProblemSetProblemInfo:(NSUInteger) problemIndex {
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(ToolbeltItem *item, NSDictionary *bindings) {
        if (item.level == (problemIndex + 1)) {
            return YES;
        }
        return NO;
    }];
    
    return [[self all] filteredArrayUsingPredicate:pred];
}


@end
