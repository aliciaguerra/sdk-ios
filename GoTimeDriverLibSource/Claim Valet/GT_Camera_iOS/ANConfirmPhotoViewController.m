//
//  ANConfirmPhotoViewController.m
//  Claim Valet
//
//  Created by Anthony Doan on 6/27/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import "ANConfirmPhotoViewController.h"

@implementation ANConfirmPhotoViewController

@synthesize delegate;
@synthesize photoImage;
@synthesize ivPhoto;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *currentImg = self.photoImage;
    self.ivPhoto.image = currentImg;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// If user selects Use, then dismiss confirm photo screen and call delegate's onCaptureImage.
- (IBAction)usePhoto:(id)sender
{
    [self saveMetrics:@"PhotoConfirm_Use_ButtonClicked"];
 
    [self dismissViewControllerAnimated:NO completion:^(void)
    {
        if (self.delegate)
        {
            [self.delegate onCaptureImage:self.photoImage];
        }
    }];
}

// If user selects Retake, then dismiss confirm photo screen back to camera view.
- (IBAction)retakePhoto:(id)sender
{
    [self saveMetrics:@"PhotoConfirm_Retake_ButtonClicked"];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

@end
