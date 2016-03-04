//
//  ANAdditionalImageViewController.h
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 8/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaimViewController.h"
#import "ANCameraViewController.h"
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface ANAdditionalImageViewController : ANClaimViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate,ANCameraViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage1;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage2;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage3;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage4;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage5;

@property (weak, nonatomic) IBOutlet UIButton *addAdditionalImage6;

@end
