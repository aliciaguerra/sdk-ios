//
//  ANBaseWelcomeViewController.h
//  Self-ServiceEstimateLib
//
//  Created by Quan Nguyen on 8/19/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANClaimViewController.h"
#import "SSZipArchive.h"

@interface ANBaseWelcomeViewController : ANClaimViewController<UIScrollViewDelegate, SSZipArchiveDelegate>

@property (nonatomic, assign) BOOL bShouldDownloadGraphic;
@property (strong, nonatomic) NSString *strWelcomeText;
@property (strong, nonatomic) NSString *strStartButtonText;

- (void)moveToVehicleSelection;
- (void)moveToDamageViewer;

@end
