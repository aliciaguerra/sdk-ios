//
//  GTDSSelectMakeViewController.h
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

@interface GTDSSelectMakeViewController : ANClaimViewController <UITableViewDelegate, UITableViewDataSource, NSURLConnectionDelegate, MBProgressHUDDelegate>
{
    NSMutableArray *makesArr;
    MBProgressHUD *HUD;
}

@property (nonatomic, retain) IBOutlet UITableView *tvMakes;
@property (retain, nonatomic) NSMutableData *receivedData;

- (IBAction)backClicked:(id)sender;

@end
