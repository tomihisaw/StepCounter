//
//  CountStepsTests.m
//  CountStepsTests
//
//  Created by tw178 on 12/7/15.
//  Copyright © 2015 DCRI. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "StepDetector.h"

@interface CountStepsTests : XCTestCase

@end

@implementation CountStepsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {

    NSUInteger steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-4-4s-10Hz~200"];
    XCTAssert(steps==197);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-4-6s-10Hz~200"];
    XCTAssert(steps==216);

    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk550-4s"];
    XCTAssert(steps==531);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk550-4s"];
    XCTAssert(steps==531);

    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-234"];
    XCTAssert(steps==240);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-234"];
    XCTAssert(steps==268);

    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-887"];
    XCTAssert(steps==998);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-887"];
    XCTAssert(steps==990);

    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-597"];
    XCTAssert(steps==584);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-597"];
    XCTAssert(steps==646);

    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk-150-dcriloop-4s"];
    XCTAssert(steps==128);
    steps = [[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk322-6s"];
    XCTAssert(steps==301);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
