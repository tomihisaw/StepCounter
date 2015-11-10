//
//  DCRIStepDetector.m
//  CountSteps
//
//  Created by tw178 on 11/10/15.
//  Copyright © 2015 DCRI. All rights reserved.
//

#import "StepDetector.h"

@import CoreMotion;

#define kUpdateInterval 0.01f

@interface StepCountingSession : NSObject
@property(nonatomic,assign) int windowSize;
@property(nonatomic,assign) double lastStepTimestamp;
@property(nonatomic,assign) double startTime;
@property(nonatomic,assign) int sampleNumber;
@property(nonatomic,assign) double lastMagnitude;
@property(nonatomic,assign) double minValue;
@property(nonatomic,assign) double maxValue;
@property(nonatomic,assign) double thresholdValue;
-(void) beginCounting;
-(BOOL) addSample:(CMAcceleration)acceleration withTime:(NSTimeInterval)timestamp;
@end

@interface StepDetector()
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMPedometer *pedometer;
@property (strong, nonatomic) NSOperationQueue* queue;
@property (nonatomic,strong) NSMutableArray *data; // for logging
@property (nonatomic,strong) NSDate *startTime;
@property(nonatomic,assign) long stepCount;
@property (nonatomic,strong) StepCountingSession *session;
@end

@implementation StepDetector
+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    
    self.pedometer = [CMPedometer new];
    
    self.motionManager = [CMMotionManager new];
    self.motionManager.accelerometerUpdateInterval = kUpdateInterval;
    
    self.queue = [NSOperationQueue new];
    self.queue.maxConcurrentOperationCount = 1;
    
    return self;
}

- (BOOL)usingBuiltInPedometer {
    return [CMPedometer isStepCountingAvailable];
}

-(NSString*)createLogFile
{
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *timeStampString = [NSString stringWithFormat:@"%ld", (long int)[@([NSDate timeIntervalSinceReferenceDate]) integerValue]];
    NSString *fileName = [NSString stringWithFormat:@"%@.json", timeStampString];
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:fileName];
    return filePath;
}

- (void)startCountingWithLogging:(BOOL)log updateBlock:(void (^)(NSError *))callback
{
    self.stepCount = 0;
    
    if ([self usingBuiltInPedometer]){
        [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if(error){
                if (callback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback (error);
                    });
                }
            }
            else {
                long lastCount = self.stepCount;
                if (callback) {
                    self.stepCount = [pedometerData.numberOfSteps integerValue];
                    for(int i = 0; i < self.stepCount - lastCount; i++){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            callback (nil);
                        });
                    }
                }
            }
        }];
    }
    if (!self.motionManager.isAccelerometerActive) {
        self.session = [StepCountingSession new];
        [self.session beginCounting];
        if(log)
            self.data = [NSMutableArray new];
        self.startTime = [NSDate date];
        
        [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            if (error) {
                if (callback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback (error);
                    });
                }
            }
            else {
                NSTimeInterval timeValue = [NSDate timeIntervalSinceReferenceDate];
                if(log){
                    NSNumber *timestamp = @(timeValue);
                    [self.data addObject:@{@"x":@(accelerometerData.acceleration.x),
                                           @"y":@(accelerometerData.acceleration.y),
                                           @"z":@(accelerometerData.acceleration.z),
                                           @"timestamp":timestamp}];
                }
                if(![self usingBuiltInPedometer]){
                    if ([self.session addSample:accelerometerData.acceleration withTime:timeValue]) {
                        self.stepCount++;
                        if (callback) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                callback (nil);
                            });
                        }
                    }
                }
            }
        }];
    }
}

- (void)stopCounting
{
    if ([self usingBuiltInPedometer]){
        [self.pedometer stopPedometerUpdates];
    }
    if (self.motionManager.isAccelerometerActive) {
        [self.motionManager stopAccelerometerUpdates];
        
        if(self.data.count){
            NSError *writeError = nil;
            NSTimeInterval elapsedTime = [[NSDate date]timeIntervalSinceDate:self.startTime];
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"MMM dd, yyyy HH:mm"];
            
            NSData* data =[NSJSONSerialization dataWithJSONObject:@{@"finishTime":[format stringFromDate:[NSDate date]],
                                                                    @"stepCount":@(self.stepCount),
                                                                    @"items":self.data,
                                                                    @"elapsedTime":@(elapsedTime)} options:NSJSONWritingPrettyPrinted error:&writeError];
            [data writeToFile:[self createLogFile] options:(NSDataWritingOptions)0 error:&writeError];
            NSAssert(writeError==nil,@"error writing");
            if(self.data)
                [self.data removeAllObjects];
        }
    }
}

// Load json file from documents directory and count steps
-(NSUInteger)stepsInJSONFile:(NSString*)filename
{
    StepCountingSession *session = [StepCountingSession new];
    [session beginCounting];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    NSLog(@"reading file %@",path);
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    NSDictionary *jsonFile = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];
    NSAssert(error==nil, @"Error reading json (format?)");
    
    NSArray *values = [jsonFile objectForKey:@"items"];
    NSUInteger steps = 0;
    
    double intervalTime = 0;
    NSUInteger samples=0;
    double startTime = [[((NSDictionary*)[values objectAtIndex:0])objectForKey:@"timestamp"]doubleValue];
    
    for(NSDictionary *item in values) {
        if([item isKindOfClass:[NSDictionary class]]){
            NSNumber *xValue = item[@"x"];
            NSNumber *yValue = item[@"y"];
            NSNumber *zValue = item[@"z"];
            NSNumber *timestampValue = item[@"timestamp"];
            
            intervalTime += [timestampValue doubleValue]-startTime;
            startTime = [timestampValue doubleValue];
            
            CMAcceleration acceleration;
            acceleration.x = [xValue doubleValue];
            acceleration.y = [yValue doubleValue];
            acceleration.z = [zValue doubleValue];
            
            if ([session addSample:acceleration withTime:[timestampValue doubleValue]]) {
                steps++;
            }
            samples++;
        }
    }
        double sampleRate = intervalTime / (double)samples;
        NSLog(@"sample rate: %3f",sampleRate);
        NSLog(@"interval: %2f",[[[values lastObject]objectForKey:@"timestamp"]doubleValue]-[[[values firstObject]objectForKey:@"timestamp"]doubleValue]);
        NSLog(@"[[ %lu Steps]]",steps);
    return steps;
}

@synthesize motionManager = _motionManager;
@synthesize pedometer = _pedometer;
@synthesize queue = _queue;
@synthesize startTime = _startTime;
@synthesize stepCount = _stepCount;
@synthesize session = _session;
@end

@implementation StepCountingSession

+(double)distanceForAcceleration:(CMAcceleration)acceleration {
    return sqrt(acceleration.x*acceleration.x+acceleration.y*acceleration.y+acceleration.z*acceleration.z);
}

-(void)beginCounting
{
    self.windowSize = 10; // initial guess
    self.lastStepTimestamp=0;
    self.lastMagnitude = 0;
    self.sampleNumber = 0;
    self.minValue = DBL_MAX;
    self.maxValue = DBL_MIN;
    self.startTime = 0;
}

-(void)updateWindow:(double)magnitude time:(double)timestamp
{
    self.minValue = MIN(self.minValue, magnitude);
    self.maxValue = MAX(self.maxValue, magnitude);
    
    // use a moving window to determine threshold from min/max
    if(self.sampleNumber++ % self.windowSize == self.windowSize-1) {
        
        // reset threshold at end of window
        self.thresholdValue = (self.minValue + self.maxValue) / 2.0;
        
        self.minValue = magnitude;
        self.maxValue = magnitude;
        
        if(self.startTime == 0.0) {
            self.startTime = timestamp;
        }
        else{
            // window range varies with current sample rate. Tries to maintain a length of ~150 ms
            double average = (timestamp-self.startTime) / (double)self.sampleNumber;;
            self.windowSize = MAX(2,MIN(20, (int)(0.15/average))); // clamp [2,20]
        }
    }
}

-(BOOL)addSample:(CMAcceleration)acceleration withTime:(NSTimeInterval)timestamp
{
    // use euclidean magnitude of vector
    double magnitude = [StepCountingSession distanceForAcceleration:acceleration];
    
    [self updateWindow:magnitude time:timestamp];
    
    if( fabs(magnitude-self.lastMagnitude) < 0.5*self.thresholdValue ) //remove high freq
        magnitude = self.lastMagnitude;
    
    BOOL hasBeenLongEnough = timestamp - self.lastStepTimestamp > 0.2; // fastest reasonable pace (5 steps/second)
    if( self.lastMagnitude > self.thresholdValue && magnitude < self.thresholdValue && hasBeenLongEnough ){
        self.lastStepTimestamp = timestamp;
        self.lastMagnitude = magnitude;
        return YES;
    }
    else{
        self.lastMagnitude = magnitude;
        return NO;
    }
}

@synthesize windowSize=_windowSize;
@synthesize lastStepTimestamp=_lastStepTimestamp;
@synthesize lastMagnitude=_lastMagnitude;
@synthesize startTime=_startTime;
@synthesize sampleNumber=_sampleNumber;
@synthesize minValue=_minValue;
@synthesize maxValue=_maxValue;
@synthesize thresholdValue=_thresholdValue;

@end
