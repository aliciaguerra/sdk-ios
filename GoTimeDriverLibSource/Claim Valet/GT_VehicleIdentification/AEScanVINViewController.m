//
//  AEScanVINViewController.m
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "AEScanVINViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AEScanVINZBarViewController.h"

#define kAE_MAX_VIN_LENGTH 17

@implementation AEScanVINViewController
{
    __weak IBOutlet UIButton        *_buttonForCancel;
    BOOL bGotVin;
}

@synthesize ivCameraOverlay;
@synthesize imgClose;
@synthesize btnClose;
@synthesize ivWhereVIN;
@synthesize btnWhereVIN;

#pragma mark - actions

- (IBAction)buttonPressedClose:(id)sender {
    [self saveMetrics:@"VIDScanVIN_Close_ButtonClicked"];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.capture stop];
	[self.delegate scanVINDidCancel];
}

#pragma mark - setup

- (void)setupReader {
    self.capture = [[ZXCapture alloc] init];
    if(self.capture.reader == nil) {
        self.capture.reader = [ZXMultiFormatReader reader];
    }

    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.rotation = -90.0;
    self.capture.hints.tryHarder = YES;

    [self.capture.hints addPossibleFormat:kBarcodeFormatCode128];
    [self.capture.hints addPossibleFormat:kBarcodeFormatDataMatrix];
    [self.capture.hints addPossibleFormat:kBarcodeFormatCode39];
    [self.capture.hints addPossibleFormat:kBarcodeFormatQRCode];

    self.capture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.capture.layer];
    self.vScanArea.hidden = YES;
}

#pragma mark - lifecycle
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    [self saveMetrics:@"VIDScanVIN_PageLoaded"];
    
	[self setupReader];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.btnLinearBarcode.frame = CGRectMake(20, 290, 55, 108);
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.view bringSubviewToFront:self.ivCameraOverlay];
    [self setupWhereVIN];
    
    [self.view bringSubviewToFront:_buttonForCancel];
    [self.view bringSubviewToFront:self.btnLinearBarcode];
}

- (void) showWhereVinGraphic {
    [super showWhereVinGraphic];
    [self saveMetrics:@"VIDScanVIN_WhereIsMyVIN_ButtonClicked"];
    
    imgClose = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/button_close.png", AUDAEXPLORE_GTD_BUNDLE]]];
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.ivCameraOverlay.frame = CGRectMake(0, 0, 320, 480);
        self.ivCameraOverlay.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/mask_2d_iphone4.png", AUDAEXPLORE_GTD_BUNDLE]];
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
    
    [self.btnLinearBarcode setHidden:YES];
}

- (void) hideWhereVinGraphic {
    [super hideWhereVinGraphic];
    
    [imgClose setHidden:YES];
    [btnClose setHidden:YES];
    [self.ivCameraOverlay setHidden:NO];
    [_buttonForCancel setHidden:NO];
    
    [self.btnLinearBarcode setHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    self.capture.delegate = self;
    self.capture.layer.frame = self.view.bounds;
    self.capture.scanRect = self.vScanArea.frame;
    bGotVin = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.capture stop];
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    [self.capture stop];
    if (!result) {
        return;
    }
    
    NSString *possibleVIN = result.text;
    NSLog(@"Got barcode %@", possibleVIN);

    //ZXing calls captureResult twice for the same scan.  Use bGotVin to block out all the subsequent calls.
    if (!bGotVin) {
        [self saveMetrics:@"VIDScanVIN_ScanSuccessful"];
        
        if ([[possibleVIN substringToIndex:1] isEqualToString:@"I"]) {
            possibleVIN = [possibleVIN substringFromIndex:1];
        }
        
        if (possibleVIN.length > kAE_MAX_VIN_LENGTH) {
            possibleVIN = [possibleVIN substringToIndex:kAE_MAX_VIN_LENGTH];
        }

        [self.delegate scanVINDidScan:possibleVIN];
        bGotVin = YES;
    }
}

- (IBAction)useZBarScanner:(id)sender {
    [self saveMetrics:@"VIDScanVIN_SwitchScanner_ButtonClicked"];
    
    AEScanVINZBarViewController *viewController = [[AEScanVINZBarViewController alloc] initWithNibName:@"AEScanVINZBarViewController"];
    
    viewController.delegate = self.delegate;
    viewController.claim = self.claim;
    [UIView animateWithDuration:0.75
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                         [self.navigationController pushViewController:viewController animated:NO];
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                                                forView:self.navigationController.view cache:NO];
                     }];
    
    NSMutableArray *controllers = [[NSMutableArray alloc] initWithArray:self.navigationController.viewControllers];
    
    [controllers removeObjectAtIndex:[controllers count] - 2];
    
    [self.navigationController setViewControllers:controllers];
}

@end
