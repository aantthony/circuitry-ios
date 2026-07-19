//
//  MongoIDTest.m
//  Circuitry
//
//  Created by Anthony Foster on 2/02/2014.
//  Copyright (c) 2014 Circuitry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MongoID.h"
#import "Circuit.h"

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

- (void)testCircuitNotesRoundTripTheirTextAndRectangle
{
    NSDictionary *saved = @{
        @"_id": @"note-1",
        @"text": @"Control section",
        @"rect": @[@12.5, @30.0, @640.0, @180.0]
    };
    CircuitNote *note = [[CircuitNote alloc] initWithDictionary:saved];

    XCTAssertEqualObjects(note.identifier, @"note-1");
    XCTAssertEqualObjects(note.text, @"Control section");
    XCTAssertTrue(CGRectEqualToRect(note.frame, CGRectMake(12.5, 30.0, 640.0, 180.0)));
    XCTAssertEqualObjects(note.dictionaryRepresentation, saved);
}

- (void)testCircuitLoadsNotesWithoutTreatingThemAsSimulationObjects
{
    NSDictionary *package = @{
        @"name": @"notes-test",
        @"version": @"1",
        @"title": @"Notes",
        @"author": @"",
        @"license": @"",
        @"notes": @[@{@"text": @"A note", @"rect": @[@0, @0, @300, @120]}]
    };
    Circuit *circuit = [[Circuit alloc] initWithPackage:package items:@[]];

    XCTAssertEqual(circuit.notes.count, 1u);
    XCTAssertEqualObjects(circuit.notes.firstObject.text, @"A note");
    __block NSUInteger objectCount = 0;
    [circuit enumerateObjectsUsingBlock:^(CircuitObject *object, BOOL *stop) {
        objectCount++;
    }];
    XCTAssertEqual(objectCount, 0u);
}

@end
