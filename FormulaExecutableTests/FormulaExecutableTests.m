//
//  FormulaExecutableTests.m
//  FormulaExecutableTests
//
//  Created by Gaige B. Paulsen on 12/29/19. See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import <XCTest/XCTest.h>
#import "FormulaExecutorProxy.h"
#import "MapGeometryExternalProxy.h"

@interface FormulaExecutableTests : XCTestCase
@property(retain) FormulaExecutorProxy *connectionToService;
@end

@implementation FormulaExecutableTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _connectionToService = [[FormulaExecutorProxy alloc] init];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _connectionToService = nil;
}

- (void)testConstant {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService validateFormula:@"1" forEntity: nil andInfo:nil withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects( result, @1);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMath {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService validateFormula:@"422/2" forEntity: nil andInfo:nil withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects( result, @211);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testDate {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService validateFormula:@"datetime.now()" forEntity: nil andInfo:nil withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertTrue( [result isKindOfClass: NSDate.class]);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMathWithVariable {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService validateFormula:@"500/a" forEntity: nil andInfo: @{@"a":@4} withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects(result, @125);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testUnknownVariable {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService validateFormula:@"500/z" forEntity: nil andInfo: @{@"a":@4} withReply:^(id result, NSError *error) {
        XCTAssertEqualObjects(error.domain, @"com.ClueTrust.Cartographica.Computation");
        XCTAssertEqual(error.code, kComputationError_unknownSymbol);
        XCTAssertEqualObjects(error.userInfo[kComputationError_unknownSymbolErrorKey], @"z");
        XCTAssertNil( result);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testArea {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    MapGeometry *geometry = [[MapGeometry alloc] initWithRect: CGRectMake(0, 0, 20, 10)];
    MapGeometryExternalProxy *geometryProxy = [MapGeometryExternalProxy mapGeometryExternalProxyWithMapGeometry: geometry];
    
    [_connectionToService validateFormula:@"geometry.area()" forEntity: geometryProxy andInfo: @{@"a":@4} withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects(result, @400);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testBaseArea {
    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    MapGeometry *geometry = [[MapGeometry alloc] initWithRect: CGRectMake(0, 0, 20, 10)];
    MapGeometryExternalProxy *geometryProxy = [MapGeometryExternalProxy mapGeometryExternalProxyWithMapGeometry: geometry];
    
    [_connectionToService validateFormula:@"geometry.area(1)" forEntity: geometryProxy andInfo: @{@"a":@4} withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects(result, @200);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

@end
