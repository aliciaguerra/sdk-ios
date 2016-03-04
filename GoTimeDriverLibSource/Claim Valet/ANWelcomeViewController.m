//
//  ANWelcomeViewController.m
//  Self-ServiceEstimateLib
//
//  Created by Quan Nguyen on 8/5/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ANWelcomeViewController.h"
#import "ANWebGLPlaceHolderViewController.h"


@interface ANWelcomeViewController(){
    NSURL *videoURL;
}

@property (strong, nonatomic) IBOutlet UILabel *ownerName;
@property (weak, nonatomic) IBOutlet UILabel *lblWelcome;
@property (strong, nonatomic) IBOutlet UILabel *vehicle;
@property (strong, nonatomic) IBOutlet UIButton *btnStart;

@end

@implementation ANWelcomeViewController 
@synthesize ownerName;
@synthesize lblWelcome;
@synthesize vehicle;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.strWelcomeText != nil) {
        ownerName.text = self.strWelcomeText;
        [lblWelcome setHidden:YES];
    } else {
        //set vehicle owner name
        NSString *strName = self.claim.ownerName;
        if(strName == nil || [strName isEqualToString:@""]) {
            strName = @"";
        } else {
            strName = [NSString stringWithFormat:@" %@", strName];
        }
        
        NSString *labelWelcomeText = [ownerName text];
        labelWelcomeText = [labelWelcomeText stringByReplacingOccurrencesOfString:@"<ownerName>" withString:strName];
        ownerName.text = labelWelcomeText;
    }

    if(self.strStartButtonText != nil) {
        [self.btnStart setTitle:self.strStartButtonText forState:UIControlStateNormal];
    }
    
    //set vehicle
    self.vehicle.text = self.claim.yearMakeModel;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Enable the next button
    [self.btnStart setEnabled:YES];
    self.btnStart.userInteractionEnabled = YES;
}

- (IBAction)playVideoClicked:(UIButton *)sender {
    [self saveMetrics:@"Welcome_PlayVideo_ButtonClicked"];
    [self enableSound];
    
    NSMutableDictionary *lbClaim = self.claim.lbObject;
    NSArray *claimArray = self.claim.lbObject.allKeys;
    NSMutableDictionary *claimDict = [[lbClaim dictionaryWithValuesForKeys:claimArray] mutableCopy];
    NSString *vehicleMake = ([claimDict objectForKey:@"estimateVehicleMake"] != nil ? [claimDict objectForKey:@"estimateVehicleMake"]:[claimDict objectForKey:@"assignmentVehicleMake"]);
    if(vehicleMake == nil) {
        [claimDict setValue:@"" forKey:@"estimateVehicleMake"];
    }
    MBProgressHUD *videoHud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    videoHud.labelText = @"Loading Video...";
    
    [self.globalInstance.loopBackAPIHelper callMobileBackEnd:USERACTIONUTILITIES_DATA_MODEL_NAME
                                            methodName:@"getVideoURLFromSundaySky"
                                            parameters:@{@"claim":claimDict, @"videoVersion":@"1"}
                                               success:^(id value) {
                                                   [videoHud hide:YES];
                                                   NSDictionary * dictionary = (NSDictionary*)value;
                                                   if (dictionary && [dictionary valueForKey:@"url"]) {
                                                       videoURL = [NSURL URLWithString:[dictionary valueForKey:@"url"]];
                                                       if (videoURL) {
                                                           MPMoviePlayerViewController* mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
                                                           mpvc.moviePlayer.shouldAutoplay = YES;
                                                           [self presentMoviePlayerViewControllerAnimated:mpvc];
                                                       }
                                                   } else {
                                                       [self showVideoIsNotAvaiable];
                                                   }
                                               } failure:^(NSError *error) {
                                                   [videoHud hide:YES];
                                                   [ANUtils errorHandle:error withLogMessage:@"Can't get video from server."];
                                                   [self showVideoIsNotAvaiable];
                                               }];
}

-(void)showVideoIsNotAvaiable {
    [self showAlertMessage:@"The video is not avaiable at this time." withTitle:@"Error"];
}

-(void)enableSound {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *setCategoryError = nil;
    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
}

- (IBAction)startProcess:(UIButton *)sender {
    //disable the next button and user interaction
    [self.btnStart setEnabled:NO];
    self.btnStart.userInteractionEnabled = NO;
    
    NSString *trimmedTitle = (self.strStartButtonText == nil ? @"Start" : @"Next");
    NSString *eventName = [NSString stringWithFormat:@"Welcome_%@_ButtonClicked", trimmedTitle];
    [self saveMetrics:eventName];    

    // If the vehicle data is provided then go directly to Damage, otherwise go to Vehicle Identification
    if (self.claim.customerStatus < ANCustomerStatusStarted) {
        [self updateClaimStatus:ANCustomerStatusStarted];
    }
    
    if (self.vehicle.text.length > 0) {
        [self moveToDamageViewer];
    } else {
        [self moveToVehicleSelection];
    }
}

- (IBAction)gotoVehicleSelection:(id)sender {
    [self saveMetrics:@"Welcome_NotMyVehicle_ButtonClicked"];
    [self moveToVehicleSelection];
}

@end

