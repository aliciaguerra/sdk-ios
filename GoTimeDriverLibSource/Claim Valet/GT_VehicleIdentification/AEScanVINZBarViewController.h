//
//  AEScanVINViewController.h
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "ANBaseVinScanViewController.h"
#import "ZBarSDK.h"
#import "AEScanVINViewController.h"

@interface AEScanVINZBarViewController : ANBaseVinScanViewController <ZBarReaderViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *ivCameraOverlay;
@property (strong, nonatomic) IBOutlet UIButton *btn2DBarcode;

- (IBAction)useZxingScanner:(id)sender;

@end
