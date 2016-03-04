//
//  AEVehicleInfoViewController.h
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "AEScanVINViewController.h"
#import "MBProgressHUD.h"
#import "ANClaimViewController.h"
#import "ANWebServiceHelper.h"


@interface AEVehicleInfoViewController : ANClaimViewController <AEScanVINViewControllerDelegate, NSURLConnectionDelegate,  MBProgressHUDDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *strOwnerNameText;
@property (strong, nonatomic) NSString *strLetStartText;

@end