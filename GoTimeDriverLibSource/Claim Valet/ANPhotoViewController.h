//
//  ANPhotoViewController.h
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/11/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaimViewController.h"
#import "ANCameraViewController.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface ANPhotoViewController : ANClaimViewController<UINavigationControllerDelegate,UIImagePickerControllerDelegate,ANCameraViewDelegate, MBProgressHUDDelegate>

@property (nonatomic) BOOL photosProcess;

+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize ;
+ (UIImage*)cropImage:(UIImage*)image toSizeScale:(CGSize)toSize;

@end
