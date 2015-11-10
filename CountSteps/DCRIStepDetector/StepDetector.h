//
//  DCRIStepDetector.h
//  CountSteps
//
//  Created by tw178 on 11/10/15.
//  Copyright © 2015 DCRI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StepDetector : NSObject
+ (instancetype) sharedInstance;
- (void) startCountingWithLogging:(BOOL)log updateBlock:(void (^)(NSError *))callback;
- (void) stopCounting;
- (NSUInteger) stepsInJSONFile:(NSString*)filename;
- (BOOL) usingBuiltInPedometer;
@end
