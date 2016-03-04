//
//  ANWebGLPlaceHolderViewController.m
//  Claim Valet
//
//  Created by Quan Nguyen on 7/8/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANWebGLPlaceHolderViewController.h"
#import "ANPhotoViewController.h"

@interface ANWebGLPlaceHolderViewController () {
    BOOL bDamageViewerPresented;
    ANWebGLDamageViewController *webGlDamageVC;
}
@end

@implementation ANWebGLPlaceHolderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self saveMetrics:@"DamageViewer_PageLoaded"];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if( ! bDamageViewerPresented) {
        webGlDamageVC = [[ANWebGLDamageViewController alloc] initWithNibName:@"ANWebGLDamageViewController"];
        webGlDamageVC.delegate = self;
        webGlDamageVC.claim = self.claim;
        [self presentViewController:webGlDamageVC animated:NO completion:nil];
        bDamageViewerPresented = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void) onNextClicked {
    [self saveMetrics:@"DamageViewer_NextButtonClicked"];
    if (self.claim.customerStatus < ANCustomerStatusDamage) {
        [self updateClaimStatus:ANCustomerStatusDamage];
    }
    
    [webGlDamageVC dismissViewControllerAnimated:NO completion:^{
        ANPhotoViewController *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANPhotoViewController alloc] initWithNibName:@"ANPhotoViewController4"];
        } else {
            viewController = [[ANPhotoViewController alloc] initWithNibName:@"ANPhotoViewController"];
        }
        viewController.claim = self.claim;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void) onBackClicked {
    [self saveMetrics:@"DamageViewer_BackButtonClicked"];
    [webGlDamageVC dismissViewControllerAnimated:NO completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void) onCancelClicked {
    [self saveMetrics:@"DamageViewer_CancelButtonClicked"];
    [webGlDamageVC dismissViewControllerAnimated:NO completion:^{
        self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL;
        self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL;
        [self sendCustomerStatusToHostApp];
        [self returnToHostApp];
    }];
}

- (void) setDamageViewerPresented:(BOOL) value{
    bDamageViewerPresented = value;
}

@end
