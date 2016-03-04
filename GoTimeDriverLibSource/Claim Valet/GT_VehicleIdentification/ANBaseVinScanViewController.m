//
//  ANBaseVinScanViewController.m
//  Claim Valet
//
//  Created by Quan Nguyen on 2/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANBaseVinScanViewController.h"

@interface ANBaseVinScanViewController ()

@end

@implementation ANBaseVinScanViewController

@synthesize delegate;

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) setupWhereVIN {
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        self.ivWhereVIN = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        NSString *whereVinImgPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VIN-iPhone4a", AUDAEXPLORE_GTD_BUNDLE];
        self.ivWhereVIN.image = [UIImage imageNamed:whereVinImgPath];
        self.ivWhereVIN.image = [[UIImage alloc] initWithCGImage: self.ivWhereVIN.image.CGImage scale: 1.0 orientation: UIImageOrientationRight];
        [self.view addSubview:self.ivWhereVIN];
        [self.ivWhereVIN setHidden:YES];
        
        self.btnWhereVIN = [[UIButton alloc] initWithFrame:CGRectMake(20, 80, 55, 108)];
        NSString *whereVinBtnPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VIN-BTNa", AUDAEXPLORE_GTD_BUNDLE];
        [self.btnWhereVIN setImage:[UIImage imageNamed:whereVinBtnPath] forState:UIControlStateNormal];
        [self.btnWhereVIN addTarget:self action:@selector(showWhereVinGraphic) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.btnWhereVIN];
        [self.btnWhereVIN setHidden:NO];
    } else {
        self.ivWhereVIN = [[UIImageView alloc] initWithFrame:self.view.frame];
        NSString *whereVinImgPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VINa", AUDAEXPLORE_GTD_BUNDLE];
        UIImage *whereVIN= [UIImage imageNamed:whereVinImgPath];
        self.ivWhereVIN.image = whereVIN;        
        self.ivWhereVIN.image = [[UIImage alloc] initWithCGImage: self.ivWhereVIN.image.CGImage scale: 1.0 orientation: UIImageOrientationRight];
        [self.view addSubview:self.ivWhereVIN];
        [self.ivWhereVIN setHidden:YES];
        
        self.btnWhereVIN = [[UIButton alloc] initWithFrame:CGRectMake(20, 140, 55, 108)];
        NSString *whereVinBtnPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VIN-BTNa", AUDAEXPLORE_GTD_BUNDLE];
        [self.btnWhereVIN setImage:[UIImage imageNamed:whereVinBtnPath] forState:UIControlStateNormal];
        [self.btnWhereVIN addTarget:self action:@selector(showWhereVinGraphic) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.btnWhereVIN];
        [self.btnWhereVIN setHidden:NO];
    }
}

- (void) showWhereVinGraphic {
    [self.btnWhereVIN setHidden:YES];
    [self.ivWhereVIN setHidden:NO];
}

- (void) hideWhereVinGraphic {
    [self.btnWhereVIN setHidden:NO];
    [self.ivWhereVIN setHidden:YES];
}

@end
