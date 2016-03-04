//
//  GTDSSelectYearViewController.h
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/11/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaimViewController.h"

@interface GTDSSelectYearViewController : ANClaimViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *yearsArr;
}

@property (nonatomic, retain) IBOutlet UITableView *tvYears;

- (IBAction)backClicked:(id)sender;
@end
