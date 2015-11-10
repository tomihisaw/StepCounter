//
//  ViewController.m
//  CountSteps
//
//  Created by tw178 on 11/10/15.
//  Copyright © 2015 DCRI. All rights reserved.
//

#import "ViewController.h"
#import "StepDetector.h"
@import AudioToolbox;

@interface ViewController ()
@property(nonatomic,assign) BOOL started;
@property(nonatomic,assign) NSUInteger count;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) NSDate *startTime;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.count = 0;
    self.started = NO;
    self.startButton.layer.borderWidth = 1.0;
    self.startButton.layer.cornerRadius = 5.0;
    self.startButton.layer.borderColor = [self.startButton titleColorForState:UIControlStateNormal].CGColor;
    [self setCountValue:0];
    
    [self.pedometerAvailable setHidden:![[StepDetector sharedInstance]usingBuiltInPedometer]];

    // set to file value
    #if TARGET_IPHONE_SIMULATOR
    
    [self setCountValue:[[StepDetector sharedInstance]stepsInJSONFile:@"data/walk550-4s"]];
//    [self setCountValue:[[StepDetector sharedInstance]stepsInJSONFile:@"data/walk550-6s"]];

//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-234"]];
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-234"]];
//    
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-887"]];
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-887"]];
//    
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-4s-597"]];
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/12-2-6s-597"]];
//    
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk-150-dcriloop-4s"]];
//    [self setCountValue:[[DCRIStepDetector sharedInstance]stepsInJSONFile:@"data/walk322-6s"]];

#endif
    
    //[self setDistanceValue:[[DCRIStepDetector sharedInstance]distanceInJSONFile:@"data/locationdata"]];
}

-(void)setCountValue:(NSUInteger)count {
    [self.countLabel1 setText:[NSString stringWithFormat:@"Steps: %lu",(unsigned long)count]];
}

- (IBAction)startPressed:(id)sender {
    self.started = !self.started;
    
    [self.startButton setTitle:(self.started ? @"Stop" : @"Start") forState:UIControlStateNormal];
    
    if (self.started) {
        self.startTime = [NSDate date];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];

        self.count = 0;
        [self setCountValue:0];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [[StepDetector sharedInstance]startCountingWithLogging:YES updateBlock:^(NSError *error) {
                [self setCountValue:self.count++];
//#warning private method
                //AudioServicesPlaySystemSound(1104);

            }];
        });
    }
    else{
        [self.timer invalidate];
        [[StepDetector sharedInstance]stopCounting];
    }
}

-(void)updateTimer:(NSTimer*)timer {
    [self setRunningTimeValue:(int)[[NSDate date] timeIntervalSinceDate:self.startTime]];
}

-(void)setRunningTimeValue:(NSUInteger)runningTime {
    [self.runningTimeLabel setText:[NSString stringWithFormat:@"Running Time: %lu",(unsigned long)runningTime]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
