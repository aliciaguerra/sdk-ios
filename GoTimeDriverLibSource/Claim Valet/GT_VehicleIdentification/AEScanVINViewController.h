//
//  AEScanVINViewController.h
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "ANBaseVinScanViewController.h"
#import "ZXingObjC.h"

@interface AEScanVINViewController : ANBaseVinScanViewController <ZXCaptureDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *ivCameraOverlay;
@property (nonatomic, strong) UIImageView *imgClose;
@property (nonatomic, strong) UIButton *btnClose;
@property (nonatomic, strong) ZXCapture *capture;
@property (strong, nonatomic) IBOutlet UIView *vScanArea;
@property (strong, nonatomic) IBOutlet UIButton *btnLinearBarcode;

- (IBAction)useZBarScanner:(id)sender;

@end
