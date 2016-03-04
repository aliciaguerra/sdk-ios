//
//  ANBaseVinScanViewController.h
//  Claim Valet
//
//  Created by Quan Nguyen on 2/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AEViewController.h"
#import <CoreLocation/CoreLocation.h>


@protocol AEScanVINViewControllerDelegate <NSObject>
- (void)scanVINDidCancel;
- (void)scanVINDidScan:(NSString *)value;
@end

@interface ANBaseVinScanViewController : AEViewController<CLLocationManagerDelegate> {
}

@property (nonatomic, weak) id<AEScanVINViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImageView *ivWhereVIN;
@property (nonatomic, strong) UIButton *btnWhereVIN;

- (void) setupWhereVIN;
- (void) showWhereVinGraphic;
- (void) hideWhereVinGraphic;
@end
