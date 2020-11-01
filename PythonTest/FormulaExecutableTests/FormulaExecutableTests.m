//
//  FormulaExecutableTests.m
//  FormulaExecutableTests
//
//  Created by Gaige B. Paulsen on 12/29/19.
//

#import <XCTest/XCTest.h>
#import "FormulaExecutorProtocol.h"

@interface FormulaExecutableTests : XCTestCase

@end

@implementation FormulaExecutableTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSXPCConnection *_connectionToService;
    
    _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.ClueTrust.FormulaExecutor"];
    _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FormulaExecutorProtocol)];
    [_connectionToService resume];

    //    Once you have a connection to the service, you can use it like this:
    XCTestExpectation *expect = [self expectationWithDescription: @"XPCComplete"];
    [_connectionToService.remoteObjectProxy validateFormula:@"1" forEntity: nil andInfo:nil withReply:^(id result, NSError *error) {
        XCTAssertNil( error);
        XCTAssertEqualObjects( result, @1);
        [expect fulfill];
    }];

    //     And, when you are finished with the service, clean up the connection like this:

    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    [_connectionToService invalidate];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
