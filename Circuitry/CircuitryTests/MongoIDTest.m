//
//  MongoIDTest.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MongoID.h"

@interface MongoIDTest : XCTestCase

@end

@implementation MongoIDTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testExample
{
    NSScanner *scanner = [NSScanner scannerWithString:@"33"];
    scanner.scanLocation = 0;
    unsigned int a;
    [scanner scanHexInt:&a];
    assert(a == 0x33);
    
    ObjectID _id = [MongoID id];
    NSString *str = [MongoID stringWithId:_id];
    ObjectID _id2 = [MongoID idWithString:str];
    if (_id2.m[0] != _id.m[0] || _id2.m[1] != _id.m[1] || _id2.m[2] != _id.m[2]) {
        XCTFail(@"Expected \"%@\" to match", str);
    }
    
}

@end
