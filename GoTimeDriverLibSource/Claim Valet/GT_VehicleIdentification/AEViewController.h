//
//  AEViewController.h
//  Gadget
//
//  Created by Silas Marshall on 7/2/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//
#import "ANClaimViewController.h"

@interface AEViewController : ANClaimViewController
	{
	UIImageView	*_imageViewBackground;
	}

- (void)hideKeyboard;
- (void)hideStandbyView;
- (void)showStandbyView;
- (void)showStandbyView:(BOOL)coverEntireWindow;

@end
