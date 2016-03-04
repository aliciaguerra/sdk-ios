//
//  AEScanVINViewController.m
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "AEScanVINZBarViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AEScanVINViewController.h"
#import "ANPhotoViewController.h"
#define kAE_MAX_VIN_LENGTH 17

@interface AEScanVINZBarViewController() {
    UIImageView *imgClose;
    UIButton *btnClose;
}

@end

@implementation AEScanVINZBarViewController {
    __weak IBOutlet UIButton        *_buttonForCancel;
    
	ZBarReaderView	*_readerView;
}

@synthesize ivCameraOverlay;
@synthesize ivWhereVIN;
@synthesize btnWhereVIN;

#pragma mark - actions

- (IBAction)buttonPressedClose:(id)sender {
    [self saveMetrics:@"VIDScanVIN_Close_ButtonClicked"];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
	[_readerView stop];
	[self.delegate scanVINDidCancel];
}

#pragma mark - setup

- (void)setupReader {
	ZBarImageScanner *imageScanner = [[ZBarImageScanner alloc] init];
    [imageScanner setSymbology:0 config:ZBAR_CFG_ENABLE to:0];
	[imageScanner setSymbology:ZBAR_CODE39 config:ZBAR_CFG_ENABLE to:1];
	[imageScanner setSymbology:ZBAR_CODE39 config:ZBAR_CFG_X_DENSITY to:0];
	[imageScanner setSymbology:ZBAR_CODE39 config:ZBAR_CFG_Y_DENSITY to:1];
	[imageScanner setSymbology:ZBAR_CODE128 config:ZBAR_CFG_ENABLE to:1];
	[imageScanner setSymbology:ZBAR_CODE128 config:ZBAR_CFG_X_DENSITY to:0];
	[imageScanner setSymbology:ZBAR_CODE128 config:ZBAR_CFG_Y_DENSITY to:1];
    [imageScanner setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:1];

	_readerView = [[ZBarReaderView alloc] initWithImageScanner:imageScanner];
	_readerView.frame = self.view.frame;
	_readerView.readerDelegate = self;
	_readerView.zoom = 1.0;
	_readerView.trackingColor = [UIColor redColor];
	[_readerView setZoom:0 animated:NO];
	[_readerView setAllowsPinchZoom:NO];
	[_readerView setTorchMode:0];

    [self.view insertSubview:_readerView aboveSubview:_imageViewBackground];
}

#pragma mark - lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    [self saveMetrics:@"VIDScanVIN_PageLoaded"];
	[self setupReader];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.btn2DBarcode.frame = CGRectMake(20, 290, 55, 108);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupWhereVIN];
    [self.view bringSubviewToFront:_buttonForCancel];
}

- (void) showWhereVinGraphic {
    [super showWhereVinGraphic];
    [self saveMetrics:@"VIDScanVIN_WhereIsMyVIN_ButtonClicked"];
    
    imgClose = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/button_close.png", AUDAEXPLORE_GTD_BUNDLE]]];
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.ivCameraOverlay.frame = CGRectMake(0, 0, 320, 480);
        self.ivCameraOverlay.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/mask_linear_iphone4.png", AUDAEXPLORE_GTD_BUNDLE]];
        imgClose.frame = CGRectMake(275, 438, 35, 35);
        btnClose = [[UIButton alloc] initWithFrame:CGRectMake(252, 416, 60, 60)];
    } else {
        CGRect btnCloseRect = _buttonForCancel.frame;
        imgClose.frame = CGRectMake(btnCloseRect.origin.x, btnCloseRect.origin.y, 35, 35);
        btnClose = [[UIButton alloc] initWithFrame:CGRectMake(btnCloseRect.origin.x - 25, btnCloseRect.origin.y - 25, 60, 60)];
    }
    
    [btnClose addTarget:self action:@selector(hideWhereVinGraphic) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:imgClose];
    [self.view addSubview:btnClose];
    
    [imgClose setHidden:NO];
    [btnClose setHidden:NO];
    [self.ivCameraOverlay setHidden:YES];
    [_buttonForCancel setHidden:YES];
}

- (void) hideWhereVinGraphic {
    [super hideWhereVinGraphic];

    [imgClose setHidden:YES];
    [btnClose setHidden:YES];
    [self.ivCameraOverlay setHidden:NO];
    [_buttonForCancel setHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_readerView start];
}

- (void)viewWillDisappear:(BOOL)animated {
	[_readerView stop];
	[super viewWillDisappear:animated];
}

#pragma mark - ZBarReaderViewDelegate

- (void)readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
	[_readerView stop];
    for (ZBarSymbol *symbol in symbols) {
        [self saveMetrics:@"VIDScanVIN_ZBarScanSuccessful"];
        
        NSString *possibleVIN = symbol.data.description;
        if ([[possibleVIN substringToIndex:1] isEqualToString:@"I"]) {
            possibleVIN = [possibleVIN substringFromIndex:1];
        }
        
        if (possibleVIN.length > kAE_MAX_VIN_LENGTH) {
            possibleVIN = [possibleVIN substringToIndex:kAE_MAX_VIN_LENGTH];
        }

        [self.delegate scanVINDidScan:possibleVIN];
        break;
    }
}

- (IBAction)useZxingScanner:(id)sender {
    [self saveMetrics:@"VIDScanVIN_SwitchScanner_ButtonClicked"];
    
    AEScanVINViewController *viewController = [[AEScanVINViewController alloc] initWithNibName:@"AEScanVINViewController"];
    
    NSLog(@"cur View contr delegate : %@", self.delegate);
    
    viewController.delegate = self.delegate;
    
    viewController.claim = self.claim;
    
    //[self presentViewController:viewController animated:YES completion:nil];
    
    
    [UIView animateWithDuration:0.75
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                         [self.navigationController pushViewController:viewController animated:NO];
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                                                forView:self.navigationController.view cache:NO];
                     }];
    
    
    /* -- Commented the following as it was crashing here ..
     
    NSMutableArray *controllers = [[NSMutableArray alloc] initWithArray:self.navigationController.viewControllers];
    
    [controllers removeObjectAtIndex:[controllers count] - 2];
    
    [self.navigationController setViewControllers:controllers]*/
}

@end
