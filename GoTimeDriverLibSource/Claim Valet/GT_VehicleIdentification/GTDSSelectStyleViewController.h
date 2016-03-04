//
//  GTDSSelectStyleViewController.h
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/13/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ANClaimViewController.h"

@interface GTDSSelectStyleViewController : ANClaimViewController <UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

@property (nonatomic, retain) NSMutableArray *fileIDsArr;
@property (nonatomic, retain) NSMutableArray *styleIDsArr;
@property (nonatomic, retain) NSMutableArray *styleNamesArr;

@property (nonatomic, retain) NSString *fileIDStr;
@property (nonatomic, retain) NSString *styleIDStr;
@property (nonatomic, retain) NSString *bodyStyleCodeStr;

@property (nonatomic, retain) IBOutlet UITableView *tvStyles;

@property (nonatomic, retain) NSMutableArray *edmundsStyleNamesArr;
@property (nonatomic, retain) NSMutableArray *edmundsStyleIDsArr;

@property (nonatomic, readwrite) BOOL showSmallFont;

- (IBAction)backClicked:(id)sender;

@end
