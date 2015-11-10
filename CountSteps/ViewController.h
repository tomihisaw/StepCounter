//
//  ViewController.h
//  CountSteps
//
//  Created by tw178 on 11/10/15.
//  Copyright © 2015 DCRI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *countLabel1;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *runningTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *pedometerAvailable;

@end

