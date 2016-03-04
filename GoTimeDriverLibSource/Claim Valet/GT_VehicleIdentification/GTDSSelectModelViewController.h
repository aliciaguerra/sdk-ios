//
//  GTDSSelectModelViewController.h
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/11/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ANClaimViewController.h"
#import "ANWebServiceHelper.h"

#define kAEInternetResourceAdaptor_DefaultProtocol KHInternetResourceRequestResponseProtocolJSON

@interface GTDSSelectModelViewController : ANClaimViewController <UITableViewDelegate, UITableViewDataSource, NSURLConnectionDelegate, MBProgressHUDDelegate>
{
    NSMutableArray *modelsArr;
    MBProgressHUD *HUD;
    
    NSMutableArray *fileIDsArr;
    NSMutableArray *styleIDsArr;
    NSMutableArray *styleNamesArr;
    
    NSMutableArray *edmundsStyleNamesArr;
    NSMutableArray *edmundsStyleIDsArr;
    
    NSString *strFileID;
    NSString *strStyleID;
    NSString *strBodyStyleCode;
    NSMutableArray *arrUniqueFileIDs;
    NSMutableArray *arrBodyStyleCodes;
}

@property (nonatomic, retain) IBOutlet UITableView *tvModels;
@property (retain, nonatomic) NSMutableData *receivedData;

- (IBAction)backClicked:(id)sender;

@end
