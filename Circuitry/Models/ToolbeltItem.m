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

+ (ToolbeltItem *) toolbeltItemWithType:(NSString *) type {
    NSArray *all = [self all];
    for(ToolbeltItem *item in all) {
        if ([item.type isEqualToString:type]) return item;
    }
    return nil;
}

+ (NSArray *) all {
    static NSArray *_all = nil;
    if (_all) return _all;
    UIImageSymbolConfiguration *noteIconConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:36.0
                                                                                                         weight:UIImageSymbolWeightRegular];
    UIImage *noteIcon = [[UIImage systemImageNamed:@"note.text"] imageByApplyingSymbolConfiguration:noteIconConfiguration];
    _all = @[
             [[ToolbeltItem alloc] initWithType:@"note" level:0 image:noteIcon name:@"Note" fullName:@"Canvas Note" subtitle:@"Canvas annotation"],
             [[ToolbeltItem alloc] initWithType:@"button" level:0 image:[UIImage imageNamed:@"switch"] name:@"Toggle switch" fullName:@"Toggle Switch" subtitle:@"Tap to latch on or off"],
             [[ToolbeltItem alloc] initWithType:@"pbtn" level:0 image:[UIImage imageNamed:@"pushbutton"] name:@"Push button" fullName:@"Momentary Push Button" subtitle:@"High only while pressed"],
             [[ToolbeltItem alloc] initWithType:@"light" level:0 image:[[UIImage imageNamed:@"led"] imageWithTintColor:UIColor.systemRedColor] name:@"LED (Red)" fullName:@"Red LED" subtitle:@"Red logic indicator"],
             [[ToolbeltItem alloc] initWithType:@"lightg" level:0 image:[[UIImage imageNamed:@"led"] imageWithTintColor:UIColor.systemGreenColor] name:@"LED (Green)" fullName:@"Green LED" subtitle:@"Green logic indicator"],
             [[ToolbeltItem alloc] initWithType:@"lightb" level:0 image:[[UIImage imageNamed:@"led"] imageWithTintColor:UIColor.systemBlueColor] name:@"LED (Blue)" fullName:@"Blue LED" subtitle:@"Blue logic indicator"],
             [[ToolbeltItem alloc] initWithType:@"lightw" level:0 image:[[UIImage imageNamed:@"led"] imageWithTintColor:[UIColor colorWithWhite:0.68 alpha:1.0]] name:@"LED (White)" fullName:@"White LED" subtitle:@"White logic indicator"],
             [[ToolbeltItem alloc] initWithType:@"or"      level:3  image:[UIImage imageNamed:@"or"]       name:@"OR" fullName: @"OR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"and"     level:2  image:[UIImage imageNamed:@"and"]      name:@"AND" fullName:@"AND Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"not"     level:5  image:[UIImage imageNamed:@"not"]      name:@"NOT" fullName: @"NOT Gate" subtitle:@"1 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"xor"     level:6  image:[UIImage imageNamed:@"xor"]      name:@"XOR" fullName:@"XOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"xnor"    level:10  image:[UIImage imageNamed:@"xnor"]     name:@"XNOR" fullName:@"XNOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"nand"    level:4  image:[UIImage imageNamed:@"nand"]     name:@"NAND" fullName:@"NAND Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"mux"     level:0  image:[UIImage systemImageNamed:@"arrow.triangle.branch"] name:@"MUX" fullName:@"2-to-1 Multiplexer" subtitle:@"A, B, select"],
             [[ToolbeltItem alloc] initWithType:@"mux4"    level:0  image:[UIImage systemImageNamed:@"arrow.triangle.branch"] name:@"4-bit MUX" fullName:@"4-bit Multiplexer" subtitle:@"Two 4-bit inputs"],
             [[ToolbeltItem alloc] initWithType:@"mux8"    level:0  image:[UIImage systemImageNamed:@"arrow.triangle.branch"] name:@"8-bit MUX" fullName:@"8-bit Multiplexer" subtitle:@"Two 8-bit inputs"],
             [[ToolbeltItem alloc] initWithType:@"counter4" level:0 image:[UIImage systemImageNamed:@"number.square"] name:@"Counter" fullName:@"4-bit Program Counter" subtitle:@"Clock, reset, load"],
             [[ToolbeltItem alloc] initWithType:@"nor"     level:10 image:[UIImage imageNamed:@"nor"]      name:@"NOR" fullName:@"NOR Gate" subtitle:@"2 in, 1 out"],
             [[ToolbeltItem alloc] initWithType:@"ha"      level:13 image:[UIImage imageNamed:@"ha"]       name:@"Half adder" fullName:@"Half Adder" subtitle:@"2 in, 2 out"],
      [[ToolbeltItem alloc] initWithType:@"fa"      level:14 image:[UIImage imageNamed:@"fa"]       name:@"Full adder" fullName:@"Full Adder" subtitle:@"3 in, 2 out"],
      [[ToolbeltItem alloc] initWithType:@"add4"    level:16 image:[UIImage imageNamed:@"add4"]     name:@"4-bit adder" fullName:@"4-bit adder" subtitle:@"8 in, 4 out"],
      [[ToolbeltItem alloc] initWithType:@"mult4"   level:17 image:[UIImage imageNamed:@"mult4"]    name:@"4-bit multiplier" fullName:@"4-bit multiplier" subtitle:@"8 in, 4 out"],
      [[ToolbeltItem alloc] initWithType:@"add8"    level:16 image:[UIImage imageNamed:@"add8"]     name:@"8-bit adder" fullName:@"8-bit adder" subtitle:@"16 in, 8 out"],
      [[ToolbeltItem alloc] initWithType:@"mult8"   level:17 image:[UIImage imageNamed:@"mult8"]    name:@"8-bit multiplier" fullName:@"8-bit multiplier" subtitle:@"16 in, 8 out"],
      [[ToolbeltItem alloc] initWithType:@"bin7seg" level:21 image:[UIImage imageNamed:@"bin7seg"]  name:@"7seg Decoder" fullName:@"BCD to 7-segment display decoder" subtitle:@"4 bit input, 7 display"],
      [[ToolbeltItem alloc] initWithType:@"7seg"    level:21 image:[UIImage imageNamed:@"7seg"]     name:@"7-Segment Display" fullName:@"7-Segment Display" subtitle:@"Display"],
      [[ToolbeltItem alloc] initWithType:@"7segbin" level:13 image:[UIImage imageNamed:@"7seg"] name:@"Number Display" fullName:@"Number Display with binary input" subtitle:@"Display"],
             
      [[ToolbeltItem alloc] initWithType:@"sr"   level:18  image:[UIImage imageNamed:@"sr"]    name:@"SR Latch" fullName:@"SR NOR Latch" subtitle:@"Set, reset, Q"],
             
             [[ToolbeltItem alloc] initWithType:@"ser"   level:19  image:[UIImage imageNamed:@"ser"]    name:@"Gated SR Latch" fullName:@"Gated SR NOR Latch" subtitle:@"Set, reset, Q"],
             
             [[ToolbeltItem alloc] initWithType:@"jk"   level:20  image:[UIImage imageNamed:@"jk"]    name:@"JK flip-flop" fullName:@"JK flip-flop" subtitle:@"clocked"],

             [[ToolbeltItem alloc] initWithType:@"t"   level:20  image:[UIImage imageNamed:@"t"]    name:@"T flip-flop" fullName:@"T flip-flop" subtitle:@"Toggle"],
             [[ToolbeltItem alloc] initWithType:@"d"   level:20  image:[UIImage imageNamed:@"d"]    name:@"D flip-flop" fullName:@"D flip-flop" subtitle:@"Delay"],
             [[ToolbeltItem alloc] initWithType:@"d4"   level:21  image:[UIImage imageNamed:@"d4"]    name:@"4-bit Register" fullName:@"4-bit D Register" subtitle:@"4x D flip-flop"],
             [[ToolbeltItem alloc] initWithType:@"d8"   level:21  image:[UIImage imageNamed:@"d8"]    name:@"8-bit Register" fullName:@"8-bit D Register" subtitle:@"8x D flip-flop"],
             [[ToolbeltItem alloc] initWithType:@"d16"   level:21  image:[UIImage imageNamed:@"d16"]    name:@"16-bit Register" fullName:@"16-bit D Register" subtitle:@"16x D flip-flop"],
      [[ToolbeltItem alloc] initWithType:@"clock"      level:7 image:[UIImage imageNamed:@"clock"] name:@"Fast clock" fullName:@"Fast Clock" subtitle:@"100 Hz square wave"],
      [[ToolbeltItem alloc] initWithType:@"slowclock"  level:7 image:[UIImage imageNamed:@"clock"] name:@"Slow clock" fullName:@"Slow Clock" subtitle:@"1 Hz square wave"]
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
