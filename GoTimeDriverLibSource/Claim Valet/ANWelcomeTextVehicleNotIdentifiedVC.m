//
//  ANWelcomeTextVehicleNotIdentifiedVC.m
//  Self-ServiceEstimateLib
//
//  Created by Quan Nguyen on 8/20/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANWelcomeTextVehicleNotIdentifiedVC.h"

@interface ANWelcomeTextVehicleNotIdentifiedVC ()

@property (strong, nonatomic) IBOutlet UILabel *ownerName;
@property (weak, nonatomic) IBOutlet UILabel *lblWelcome;
@property (strong, nonatomic) IBOutlet UIButton *btnStart;
@property (strong, nonatomic) IBOutlet UIView *vwIndicateDmg;
@property (strong, nonatomic) IBOutlet UIView *vwTakePhotos;
@property (weak, nonatomic) IBOutlet UIView *vwAddNotes;
@property (strong, nonatomic) IBOutlet UIView *vwSubmit;

@end

@implementation ANWelcomeTextVehicleNotIdentifiedVC

@synthesize ownerName;
@synthesize lblWelcome;
@synthesize vwIndicateDmg;
@synthesize vwTakePhotos;
@synthesize vwAddNotes;
@synthesize vwSubmit;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.strWelcomeText != nil) {
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Enable the next button
    [self.btnStart setEnabled:YES];
    self.btnStart.userInteractionEnabled = YES;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //hide the 3D damage instruction if WebGl is not supported.
    if( ! [self.globalInstance damageViewerEnabled] ) {
        [vwIndicateDmg setHidden:YES];
        
        CGFloat offset = vwIndicateDmg.frame.size.height;
        
        //take photo view
        CGRect photoRect = vwTakePhotos.frame;
        photoRect.origin.y -= offset;
        vwTakePhotos.frame = photoRect;
        
        //notes view
        CGRect notesRect = vwAddNotes.frame;
        notesRect.origin.y -= offset;
        vwAddNotes.frame = notesRect;
        
        //submit view
        CGRect submitRect = vwSubmit.frame;
        submitRect.origin.y -= offset;
        vwSubmit.frame = submitRect;
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
    
    [self moveToVehicleSelection];
}

@end
