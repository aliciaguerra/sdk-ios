//
//  ANAdditionalImageViewController.m
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 8/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANAdditionalImageViewController.h"
#import "ANCameraViewController.h"
#import "ANPhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ANAdditionalImageViewController () <UIActionSheetDelegate> {
    UIButton *currentButton;
    ANCameraViewController *cameraView;
    NSString *deviceType;
    CLLocationManager *locationManager;
    ANPhotoAngle lowestEnabledButtonTag;
    UIActionSheet *oldStyleActionSheet;
}
@end

@implementation ANAdditionalImageViewController
 
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *headerBG = [NSString stringWithFormat:@"%@.bundle/Header-BG.png", AUDAEXPLORE_GTD_BUNDLE];
    if([self isiPad]) {
        headerBG = [NSString stringWithFormat:@"%@.bundle/header-bg~ipad.png", AUDAEXPLORE_GTD_BUNDLE];
    }
    UIImage *imgBackground = [UIImage imageNamed:headerBG];
    [self.navigationBar setBackgroundImage:imgBackground forBarMetrics:UIBarMetricsDefault];
    [self saveMetrics:@"AdditionalPhotos_PageLoaded"];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >= 1136.0f) {
            deviceType = @"iPhone 5";
        } else {
            deviceType = @"iPhone 4";
        }
    } else {
        deviceType = @"iPhone 4";
    }
    
    [self setupPhotoCapture];
    if ( [self.globalInstance requirePhotoLocation] && [CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        [locationManager startUpdatingLocation];
    }
    
    lowestEnabledButtonTag = (ANPhotoAngle)self.addAdditionalImage1.tag;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadAnyExistingPhotos];
    [self disableEnableButtons];
}

- (void) loadAnyExistingPhotos {
    NSDictionary *filePaths = [self getAllFilePathsToUpload];
    for (NSString *filename in filePaths) {
        NSString *filePath = [filePaths objectForKey:filename];
        if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
            NSData *encryptedData = [[NSFileManager defaultManager] contentsAtPath:filePath];
            NSData *decryptedData = [self.globalInstance decrypt:encryptedData withKey:self.claim.claimNumber];
            UIImage *originalImage = [UIImage imageWithData:decryptedData];
            
            if([filename isEqualToString:@"addphoto1.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage1 image:originalImage];
            } else if([filename isEqualToString:@"addphoto2.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage2 image:originalImage];
            } else if([filename isEqualToString:@"addphoto3.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage3 image:originalImage];
            } else if ([filename isEqualToString:@"addphoto4.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage4 image:originalImage];
            } else if ([filename isEqualToString:@"addphoto5.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage5 image:originalImage];
            } else if ([filename isEqualToString:@"addphoto6.jpeg"]) {
                [self setButtonImage:self.addAdditionalImage6 image:originalImage];
            }
        }
    }
}

- (void) setButtonImage: (UIButton *)btn image:(UIImage*)originalImage {
    CGSize thumbnailSize = btn.frame.size;
    UIImage *thumbnailImage = [ANPhotoViewController cropImage:originalImage toSizeScale:thumbnailSize];
    [btn setBackgroundImage:thumbnailImage forState:UIControlStateNormal];
    
    long nextEnabledTag = btn.tag + 1;
    if(lowestEnabledButtonTag < (ANPhotoAngle)nextEnabledTag) {
        lowestEnabledButtonTag = (ANPhotoAngle)nextEnabledTag;
    }
    
    //rounded corner
    btn.layer.cornerRadius = 10;
    btn.clipsToBounds = YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [viewController.navigationItem setTitle:@""];
}

// This returns a string that will be used to record events in Server.
- (NSString*) getEventNameForPhotoClick:(ANPhotoAngle) angle {
    return [NSString stringWithFormat:@"AdditionalPhotos_AddPhoto%@_ButtonClicked",[self getAdditionalImageNumber:angle]];
}

- (void) setupPhotoCapture {
    [self.addAdditionalImage1 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.addAdditionalImage2 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.addAdditionalImage3 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.addAdditionalImage4 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.addAdditionalImage5 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.addAdditionalImage6 addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        cameraView = [[ANCameraViewController alloc] initWithNibName:@"ANCameraViewController"];
        cameraView.claim = self.claim;
        cameraView.delegate = self;
    }
}

- (void) capturePhoto:(UIButton *)sender {
    NSString *eventName = [self getEventNameForPhotoClick: (ANPhotoAngle)sender.tag];
    [self saveMetrics:eventName];
    currentButton = sender;
    
    if ([UIAlertController class]) {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [actionSheet addAction: [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self takePhoto];
        }]];
        
        [actionSheet addAction: [UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self chooseFromLibrary];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self saveMetrics:@"AdditionalPhotos_SelectCancel_ButtonClicked"];
        }]];
        
        //handle differently for ipad
        if([self isiPad]) {
            actionSheet.popoverPresentationController.sourceView = self.view;
            actionSheet.popoverPresentationController.sourceRect = sender.frame;
        }
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    } else {
        oldStyleActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles: @"Take Photo", @"Choose From Library", nil];
        [oldStyleActionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(actionSheet == oldStyleActionSheet) {
        NSLog(@"Dismiss with button %ld", (long) buttonIndex);
        if(buttonIndex == 0) {  //Take photo
            [self takePhoto];
        } else if (buttonIndex == 1) { //choose from library
            [self chooseFromLibrary];
        }
    }
}

-(void)takePhoto {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self displayCamera];
    }
    [self saveMetrics:@"AdditionalPhotos_SelectCamera_ButtonClicked"];
}

-(void)chooseFromLibrary {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
    [self saveMetrics:@"AdditionalPhotos_SelectLibrary_ButtonClicked"];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *url = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
    ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
    [al assetForURL:url resultBlock:^(ALAsset *asset) {
        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
        if (location) {
            [self.globalInstance.photoLocations setObject:[asset valueForProperty:ALAssetPropertyLocation] forKey:[self imageNameFromEnum:(ANPhotoAngle)currentButton.tag]];
        }
        [self processGalleryImage:originalImage];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error: %@",[error localizedDescription]);
        [self processGalleryImage:originalImage];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (UIImage *) resizeImage:(UIImage *)image {
    CGSize size = CGSizeMake(568, 320);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (UIImage*)cropImage:(UIImage *)image {
    CGRect croprect = CGRectMake(0, 0, 512, 320);
    if ([deviceType isEqualToString:@"iPhone 4"]) {
        croprect = CGRectMake(0, 0, 424, 320);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croprect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

-(void) displayCamera {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 55), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *overlayImage = blank;
    overlayImage = [self resizeImage:overlayImage];
    
    overlayImage = [self cropImage:overlayImage];
    
    overlayImage = [self addTextIntoImage:[self getInstructionText:(ANPhotoAngle)currentButton.tag]:overlayImage];
    overlayImage = [[UIImage alloc] initWithCGImage:overlayImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
    
    [cameraView setOverlayImage:overlayImage];
    [cameraView setPhotoAngle:(ANPhotoAngle)currentButton.tag];
    [self presentViewController:cameraView animated:YES completion:nil];
}

- (UIImage *)addTextIntoImage:(NSString *)text :(UIImage *)image {
    UIGraphicsBeginImageContext(image.size);
    CGRect rectangle = CGRectMake(0,0,image.size.width,image.size.height);
    [image drawInRect:rectangle];
    
    UIFont *font = [UIFont boldSystemFontOfSize: 16];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle, NSForegroundColorAttributeName: [UIColor whiteColor] };
    CGRect textRect = CGRectMake(0,10,image.size.width, image.size.height);
    [text drawInRect:textRect withAttributes:attributes];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(NSString*) getAdditionalImageNumber:(ANPhotoAngle) angle {
    switch (angle) {
        case additionalnumberone:return @"1";
        case additionalnumbertwo:return @"2";
        case additionalnumberthree:return @"3";
        case additionalnumberfour:return @"4";
        case additionalnumberfive:return @"5";
        case additionalnumbersix:return @"6";
        default:return nil;
    }
}

- (NSString*) getInstructionText:(ANPhotoAngle) angle {
    return @"Take an additonal photo of your vehicle";
}

- (void) onCaptureImage:(UIImage *)image {
    [self processCapturedImage:image];
    long nextEnabledTag = currentButton.tag + 1;
    
    if(lowestEnabledButtonTag < (ANPhotoAngle)nextEnabledTag) {
        lowestEnabledButtonTag = (ANPhotoAngle)nextEnabledTag;
    }
    
    currentButton = nil;
    [cameraView dismissViewControllerAnimated:NO completion:nil];
    
    [self disableEnableButtons];
}

- (void) cancelCapturing {
    [cameraView dismissViewControllerAnimated:NO completion:nil];
}

- (void) processCapturedImage:(UIImage *) image{
    //format the date string
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:now];
    
    //location string
    NSString *strLatLong = @"";
    if ([self.globalInstance requirePhotoLocation]) {
        NSDictionary *photoLocations = self.globalInstance.photoLocations;
        NSString *fileName = [self imageNameFromEnum:(ANPhotoAngle)currentButton.tag];
        CLLocation *photoLocation = [photoLocations valueForKey:fileName];
        if (photoLocation) {
            strLatLong = [NSString stringWithFormat:@"%f, %f", photoLocation.coordinate.latitude, photoLocation.coordinate.longitude];
            NSLog(@"Lat long %@", strLatLong);
        }
    }
    NSString *imageInfo = [NSString stringWithFormat:@"%@\n%@", strLatLong, dateString];

    UIImage *tempImage,*currentImage;
    if (image.size.width > image.size.height) {
        if (image.size.height < 480) {
            currentImage = [self drawText:imageInfo inImage:image atPoint:CGPointMake(image.size.width/10, image.size.height * 7/10)];
        } else {
            float fNewWidth = (480 * image.size.width) / image.size.height;
            tempImage = [ANPhotoViewController imageWithImage:image scaledToSizeWithSameAspectRatio:CGSizeMake(fNewWidth, 480)];
            currentImage = [self drawText:imageInfo inImage:tempImage atPoint:CGPointMake(50, 400)];
        }
    } else {
        if (image.size.width < 480) {
             currentImage = [self drawText:imageInfo inImage:image atPoint:CGPointMake(image.size.width/10, image.size.height * 7/10)];
        } else {
            float fNewHeight = (480 * image.size.height) / image.size.width;
            tempImage = [ANPhotoViewController imageWithImage:image scaledToSizeWithSameAspectRatio:CGSizeMake(480,  fNewHeight)];
            currentImage = [self drawText:imageInfo inImage:tempImage atPoint:CGPointMake(50, 780)];
        }
    }

    NSString *fullPathToFile;
    fullPathToFile = [self fileNameFromImageEnum:(ANPhotoAngle)currentButton.tag];
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.8f);
    NSData *encryptedImage = [self.globalInstance encrypt:imageData withKey:self.claim.claimNumber];
    [encryptedImage writeToFile:fullPathToFile atomically:NO];
    
    //enable the next button
    long nextEnabledTag = currentButton.tag + 1;
    if(lowestEnabledButtonTag < (ANPhotoAngle)nextEnabledTag) {
        lowestEnabledButtonTag = (ANPhotoAngle)nextEnabledTag;
    }
    [self disableEnableButtons];
}

- (UIImage*) drawText:(NSString*)text inImage:(UIImage*)image atPoint:(CGPoint)point {
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    UIFont *font = [UIFont systemFontOfSize:18];
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle,
                                  NSForegroundColorAttributeName: [UIColor yellowColor]};
    [text drawInRect:rect withAttributes:attributes];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (IBAction)doneFunc:(UIBarButtonItem *)sender {
    [self saveMetrics:@"AdditionalPhotos_Done_ButtonClicked"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) disableEnableButtons {
    self.addAdditionalImage1.enabled = (self.addAdditionalImage1.tag <= lowestEnabledButtonTag);
    self.addAdditionalImage2.enabled = (self.addAdditionalImage2.tag <= lowestEnabledButtonTag);
    self.addAdditionalImage3.enabled = (self.addAdditionalImage3.tag <= lowestEnabledButtonTag);
    self.addAdditionalImage4.enabled = (self.addAdditionalImage4.tag <= lowestEnabledButtonTag);
    self.addAdditionalImage5.enabled = (self.addAdditionalImage5.tag <= lowestEnabledButtonTag);
    self.addAdditionalImage6.enabled = (self.addAdditionalImage6.tag <= lowestEnabledButtonTag);

    UIImage *cameraIcon = [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/add_photo_first_image.png", AUDAEXPLORE_GTD_BUNDLE]];
    if(self.addAdditionalImage1.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage1 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
    
    if(self.addAdditionalImage2.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage2 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
    
    if(self.addAdditionalImage3.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage3 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
    
    if(self.addAdditionalImage4.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage4 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
    
    if(self.addAdditionalImage5.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage5 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
    
    if(self.addAdditionalImage6.tag == lowestEnabledButtonTag) {
        [self.addAdditionalImage6 setBackgroundImage:cameraIcon forState:UIControlStateNormal];
    }
}

- (void) processGalleryImage:(UIImage *) image{
    //resize the gallery image down to height 480 and retain aspect ratio
    CGFloat imgWidth = image.size.width;
    CGFloat imgHeight = image.size.height;
    CGFloat newHeight = 480;
    CGFloat newWidth = (newHeight * imgWidth) / imgHeight;
    
    CGSize targetSize = CGSizeMake(newWidth, newHeight);
    UIImage * resizedImage = [self resizeImage:image toFitInSize:targetSize];

    NSString *fullPathToFile;
    fullPathToFile = [self fileNameFromImageEnum:(ANPhotoAngle)currentButton.tag];
    
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
    NSData *encryptedImage = [self.globalInstance encrypt:imageData withKey:self.claim.claimNumber];
    [encryptedImage writeToFile:fullPathToFile atomically:NO];
    
    //enable the next button
    long nextEnabledTag = currentButton.tag + 1;
    if(lowestEnabledButtonTag < (ANPhotoAngle)nextEnabledTag) {
        lowestEnabledButtonTag = (ANPhotoAngle)nextEnabledTag;
    }
    [self disableEnableButtons];
}

- (UIImage*)resizeImage:(UIImage*)image toFitInSize:(CGSize)toSize {
    UIImage *result = image;
    CGSize sourceSize = image.size;
    CGSize targetSize = toSize;
    
    BOOL needsRedraw = NO;
    
    // Check if width of source image is greater than width of target image
    // Calculate the percentage of change in width required and update it in toSize accordingly.
    
    if (sourceSize.width > toSize.width) {
        CGFloat ratioChange = (sourceSize.width - toSize.width) * 100 / sourceSize.width;
        toSize.height = sourceSize.height - (sourceSize.height * ratioChange / 100);
        needsRedraw = YES;
    }
    
    // Now we need to make sure that if we chnage the height of image in same proportion
    // Calculate the percentage of change in width required and update it in target size variable.
    // Also we need to again change the height of the target image in the same proportion which we
    /// have calculated for the change.
    
    if (toSize.height < targetSize.height) {
        CGFloat ratioChange = (targetSize.height - toSize.height) * 100 / targetSize.height;
        toSize.height = targetSize.height;
        toSize.width = toSize.width + (toSize.width * ratioChange / 100);
        needsRedraw = YES;
    }
    
    // To redraw the image
    if (needsRedraw) {
        UIGraphicsBeginImageContext(toSize);
        [image drawInRect:CGRectMake(0.0, 0.0, toSize.width, toSize.height)];
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Return the result
    return result;
}

@end
