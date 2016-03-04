//
//  ANCameraViewController.h
//  Claim Valet
//
//  Created by Tung Hoang on 3/19/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaim.h"
#import <CoreMotion/CoreMotion.h>
#import "ANClaimViewController.h"
#import <CoreLocation/CLLocationManagerDelegate.h>

@protocol ANCameraViewDelegate

- (void) onCaptureImage:(UIImage *) image;
- (void) cancelCapturing;

@end

@interface ANCameraViewController : ANClaimViewController<CLLocationManagerDelegate>

@property (nonatomic, assign) id<ANCameraViewDelegate> delegate;
@property (nonatomic, retain) CMMotionManager *motionManager;

- (void) setOverlayImage:(UIImage *) image;
- (void) setPhotoAngle:(ANPhotoAngle) iPhotoAngle;

@end
