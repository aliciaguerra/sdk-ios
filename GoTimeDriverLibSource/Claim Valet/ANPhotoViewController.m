//
//  ANPhotoViewController.m
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/11/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import "ANPhotoViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "ANThankYouViewController.h"
#import "ANCameraViewController.h"
#import "ANAdditionalImageViewController.h"
#import "ANSubmitViewController.h"

#define DAMAGE_PHOTOS_OFFSET 15
#define GENERAL_PHOTOS_OFFSET 45

@interface ANPhotoViewController () {
    UIButton *currentButton;
    ANCameraViewController *cameraView;
    NSString *deviceType;
    NSMutableSet *filesUploaded;  
    bool isUploaded;
    MBProgressHUD *HUD;
}

@property (weak, nonatomic) IBOutlet UIButton *btnDamageLeft;
@property (weak, nonatomic) IBOutlet UIButton *btnDamageCenter;
@property (weak, nonatomic) IBOutlet UIButton *btnDamageRight;
@property (weak, nonatomic) IBOutlet UIButton *btnVin;
@property (weak, nonatomic) IBOutlet UIButton *btnOdometer;
@property (weak, nonatomic) IBOutlet UIButton *btnLeftFront;
@property (weak, nonatomic) IBOutlet UIButton *btnLeftRear;
@property (weak, nonatomic) IBOutlet UIButton *btnRightRear;
@property (weak, nonatomic) IBOutlet UIButton *btnRightFront;
@property (weak, nonatomic) IBOutlet UIView *vwGeneralPhotos;
@property (weak, nonatomic) IBOutlet UIView *vwDamagePhotos;

@end

@implementation ANPhotoViewController

@synthesize photosProcess;

bool alertShowing;

#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)

#define FIND_MY_VIN_VIEW_ID 501
#define VIN_VIEW_ID 502
#define CLOSE_BUTTON_ID 503
#define WHERE_IS_MY_VIN_BUTTON_ID 504

- (void)viewDidLoad {
    [super viewDidLoad];
    self.metricPrefix = @"Photos";
    [self saveMetrics:@"Photos_PageLoaded"];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadAnyExistingPhotos];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    

}

- (void)moveViewDown:(UIView *)view by:(CGFloat)offset{
    CGRect rect = view.frame;
    rect.origin.y += offset;
    view.frame = rect;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    if( [self isiPad] == NO && screenWidth > 320 ) {
        [self moveViewDown:self.vwDamagePhotos by:DAMAGE_PHOTOS_OFFSET];
        [self moveViewDown:self.btnDamageLeft by:DAMAGE_PHOTOS_OFFSET];
        [self moveViewDown:self.btnDamageCenter by:DAMAGE_PHOTOS_OFFSET];
        [self moveViewDown:self.btnDamageRight by:DAMAGE_PHOTOS_OFFSET];
        
        [self moveViewDown:self.vwGeneralPhotos by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnVin by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnOdometer by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnLeftFront by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnLeftRear by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnRightRear by:GENERAL_PHOTOS_OFFSET];
        [self moveViewDown:self.btnRightFront by:GENERAL_PHOTOS_OFFSET];
    }
}

- (void) adjustViewLocation:(UIView*)view :(int)value {
    CGRect frame = [view frame];
    frame.origin.y += value;
    [view setFrame:frame];
}

// As you may have guessed by the method name, this will load photos that already exist on the phone.
- (void) loadAnyExistingPhotos {
    NSDictionary *filePaths = [self getAllFilePathsToUpload];
    for (NSString *filename in filePaths) {
        NSString *filePath = [filePaths objectForKey:filename];
        if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
            NSData *encryptedData = [[NSFileManager defaultManager] contentsAtPath:filePath];
            NSData *decryptedData = [self.globalInstance decrypt:encryptedData withKey:self.claim.claimNumber];
            UIImage *originalImage = [UIImage imageWithData:decryptedData];
            
            if([filename isEqualToString:@"damageLeft.jpg"]) {
                [self setButtonImage:self.btnDamageLeft image:originalImage];
            } else if([filename isEqualToString:@"damageCenter.jpg"]) {
                [self setButtonImage:self.btnDamageCenter image:originalImage];
            } else if([filename isEqualToString:@"damageRight.jpg"]) {
                [self setButtonImage:self.btnDamageRight image:originalImage];
            } else if ([filename isEqualToString:@"vin.jpg"]) {
                [self setButtonImage:self.btnVin image:originalImage];
            } else if ([filename isEqualToString:@"odometer.jpg"]) {
                [self setButtonImage:self.btnOdometer image:originalImage];
            } else if ([filename isEqualToString:@"leftFront.jpg"]) {
                [self setButtonImage:self.btnLeftFront image:originalImage];
            } else if ([filename isEqualToString:@"leftRear.jpg"]){
                [self setButtonImage:self.btnLeftRear image:originalImage];
            } else if ([filename isEqualToString:@"rightRear.jpg"]) {
                [self setButtonImage:self.btnRightRear image:originalImage];
            } else if ([filename isEqualToString:@"rightFront.jpg"]) {
                [self setButtonImage:self.btnRightFront image:originalImage];
            }
        }
    }
}

// Sets the button image to the photo taken for the angle.
- (void) setButtonImage: (UIButton *)btn image:(UIImage*)originalImage {
    CGSize thumbnailSize = btn.frame.size;
    UIImage *thumbnailImage = [ANPhotoViewController cropImage:originalImage toSizeScale:thumbnailSize];
    [btn setBackgroundImage:thumbnailImage forState:UIControlStateNormal];
    
    //add overlay
    UIImage *overlay = [self getPhotoReturnOverlayImage:(ANPhotoAngle)btn.tag];
    if(overlay != nil) {
        UIImageView *overlayImageView = [[UIImageView alloc] initWithImage:overlay];
        [btn addSubview:overlayImageView];
    }
    //rounded corner
    btn.layer.cornerRadius = 10;
    btn.clipsToBounds = YES;
}

// This sets the method that is called for each photo button and also starts the photo process, which will guide the user through each of the photos that they must capture before submitting.
- (void) setupPhotoCapture {
    [self.btnDamageLeft addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnDamageCenter addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnDamageRight addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnVin addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnOdometer addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnLeftFront addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnLeftRear addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnRightRear addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];
    [self.btnRightFront addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchDown];

    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        photosProcess = YES;
        
        cameraView = [[ANCameraViewController alloc] initWithNibName:@"ANCameraViewController"];
        cameraView.claim = self.claim;
        cameraView.delegate = self;
    }
}

// When the user presses a photo button then this method will be called and it will display the camera.
- (void) capturePhoto:(UIButton*)sender {
    NSString *eventName = [self getEventNameForPhotoClick:(ANPhotoAngle) sender.tag];
    [self saveMetrics:eventName];
    
    currentButton = sender;
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self displayCamera];
    }
}

// This displays the camera with an overlay that will include a custom toolbar, instructions, and possibly a photo guide.
-(void) displayCamera {
    UIImage *overlayImage = [self overlayImageToUse:(ANPhotoAngle)currentButton.tag];
    overlayImage = [self resizeImage:overlayImage];

    overlayImage = [self cropImage:overlayImage];
    
    overlayImage = [self addTextIntoImage:[self getInstructionText:(ANPhotoAngle)currentButton.tag]:overlayImage];
    overlayImage = [[UIImage alloc] initWithCGImage:overlayImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
    
    [cameraView setOverlayImage:overlayImage];
    [cameraView setPhotoAngle:(ANPhotoAngle)currentButton.tag];
    [self presentViewController:cameraView animated:YES completion:nil];
}

- (float) getScale {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    float cameraAspectRatio = 4.0 / 3.0;
    float imageWidth = floorf(screenSize.width * cameraAspectRatio);
    float scale = ceilf((screenSize.height / imageWidth) * 10.0) / 10.0;
    
    return scale;
}

// This returns a string that will be used to record events in Server.
- (NSString*) getEventNameForPhotoClick:(ANPhotoAngle) angle {
    switch (angle) {
        case damageLeft:   return @"Photos_LeftDamage_ButtonClicked";
        case damageCenter: return @"Photos_CenterDamage_ButtonClicked";
        case damageRight:  return @"Photos_RightDamage_ButtonClicked";
        case vin:          return @"Photos_VIN_ButtonClicked";
        case odometer:     return @"Photos_Odometer_ButtonClicked";
        case leftFront:    return @"Photos_LeftFront_ButtonClicked";
        case leftRear:     return @"Photos_LeftRear_ButtonClicked";
        case rightRear:    return @"Photos_RightRear_ButtonClicked";
        case rightFront:   return @"Photos_RightFront_ButtonClicked";
        default:           return nil;
    }
}

// This returns a string that will give the user instructions on what to do with the camera.
- (NSString*) getInstructionText:(ANPhotoAngle) angle {
    NSString *angleText;
    
    switch (angle) {
        case damageLeft:   return @"Take a close-up picture of the damage from the left";
        case damageCenter: return @"Take a close-up picture of the damage from the center";
        case damageRight:  return @"Take a close-up picture of the damage from the right";
        case vin:
            if([self isiPad]) {
                return @"Take a picture of your Vehicle Identification Number";
            } else {
                return @"Take a picture of your Vehicle Identification Number (VIN)";
            }
        case odometer:     return @"Take a picture of your vehicle's mileage";
        case leftFront:    angleText = @" DRIVER FRONT "; break;
        case leftRear:     angleText = @" DRIVER REAR "; break;
        case rightRear:    angleText = @" PASSENGER REAR "; break;
        case rightFront:   angleText = @" PASSENGER FRONT "; break;
        default:           return @"";
    }

    return [NSString stringWithFormat:@"%@%@%@", @"Take a picture of the", angleText, @"of your vehicle"];
}

// Closes the camera and calls a post action, which in this case will be launching the camera again to continue with the photo taking process.
- (void)dismissViewController:(UIViewController *)presentingController postAction:(SEL)postDismissalAction {
    [presentingController dismissViewControllerAnimated:YES completion:^{
        [self performSelectorOnMainThread:postDismissalAction withObject:nil waitUntilDone:NO];
    }];
}

#pragma mark - ANCameraDelegate
- (void) cancelCapturing {
    photosProcess = NO;
    [cameraView dismissViewControllerAnimated:NO completion:nil];
}

- (void) onCaptureImage:(UIImage *)image {
    [self processCapturedImage:image];
    
    if (photosProcess) {
        switch (currentButton.tag) {
            case leftFront:     currentButton = self.btnLeftRear; break;
            case leftRear:      currentButton = self.btnRightFront; break;
            case rightFront:    currentButton = self.btnRightRear; break;
            case rightRear:     currentButton = self.btnVin; break;
            case vin:           currentButton = self.btnOdometer; break;
            case odometer:      currentButton = self.btnDamageLeft; break;
            case damageLeft:    currentButton = self.btnDamageCenter; break;
            case damageCenter:  currentButton = self.btnDamageRight; break;
            default:
                photosProcess = NO;
                currentButton = nil;
                [cameraView dismissViewControllerAnimated:NO completion:nil];
        }
        if (photosProcess) {
            NSString *eventName = [self getEventNameForPhotoClick: (ANPhotoAngle)currentButton.tag];
            [self saveMetrics:eventName];
            [self dismissViewController:cameraView postAction:@selector(displayCamera)];
        }
    } else {
        [cameraView dismissViewControllerAnimated:NO completion:nil];
    }
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

- (void) processCapturedImage:(UIImage *) image {
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
    
    float fNewWidth = (480 * image.size.width) / image.size.height;
    UIImage *tempImage = [ANPhotoViewController imageWithImage:image scaledToSizeWithSameAspectRatio:CGSizeMake(fNewWidth, 480)];
    UIImage *currentImage = [self drawText:imageInfo inImage:tempImage atPoint:CGPointMake(50, 400)];
    NSString *fullPathToFile;
    fullPathToFile = [self fileNameFromImageEnum:(ANPhotoAngle)currentButton.tag];
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.8f);
    
    //encrypt
    NSData *encryptedData = [self.globalInstance encrypt:imageData withKey:self.claim.claimNumber];
    [encryptedData writeToFile:fullPathToFile atomically:NO];
}

// Resize the overlay image to 568 x 320, which is how they are currently formatted.
- (UIImage *) resizeImage:(UIImage *)image {
    CGSize size = CGSizeMake(568, 320);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

// Crop the image for to account for the width of the toolbar.
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

// Add text to the overlay image.
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

// Get the photo guide for the vehicle.
- (UIImage*)overlayImageToUse: (ANPhotoAngle) angle {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* masksDirectory = [documentsDirectory stringByAppendingPathComponent:@"Masks"];
    
    masksDirectory = [masksDirectory stringByAppendingPathComponent:deviceType];

    NSString *filename = @"screen_shot_FL3.png";
    
    if (angle == rightFront) {
        filename = @"screen_shot_FR3.png";
    } else if (angle == leftFront) {
        filename = @"screen_shot_FL3.png";
    } else if (angle == rightRear) {
        filename = @"screen_shot_RR3.png";
    } else if (angle == leftRear){
        filename = @"screen_shot_LR3.png";
    } else if (angle == vin) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"VIN-Capture" ofType:@"png"];
        
        if ([deviceType isEqualToString:@"iPhone 4"]) {
            imagePath = [[NSBundle mainBundle] pathForResource:@"VIN-Capture-iPhone4" ofType:@"png"];
        }
        
        if ([[NSFileManager defaultManager]fileExistsAtPath:imagePath]) {
            UIImage *vinImage = [UIImage imageWithContentsOfFile:imagePath];
            return vinImage;
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 55), NO, 0.0);
            UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return blank;
        }
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 55), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return blank;
    }
    
    NSString *filePath = [masksDirectory stringByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
        return [UIImage imageWithContentsOfFile:filePath];
    } else {
        return [self getGenericOverlayImage:angle];
    }
}

// Gets the generic photo guide if no specific photo guide is available.
-(UIImage*) getGenericOverlayImage: (ANPhotoAngle) angle {
    if (angle == rightFront){
        return [ANPhotoViewController imageNamedForDevice:@"rightFrontMask.png"];
    } else if(angle == leftFront) {
        return [ANPhotoViewController imageNamedForDevice:@"leftFrontMask.png"];
    } else if(angle == rightRear) {
        return [ANPhotoViewController imageNamedForDevice:@"rightRearMask.png"];
    } else if(angle == leftRear){
        return [ANPhotoViewController imageNamedForDevice:@"leftRearMask.png"];
    }
    
    return nil;
}

// Used to get the generic image when a specific photo guide isn't available.
+ (UIImage*)imageNamedForDevice:(NSString*)name {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >= 1136.0f) {
            //Check if is there a path extension or not
            if (name.pathExtension.length) {
                name = [name stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".%@", name.pathExtension]
                                                       withString: [NSString stringWithFormat:@"-568h@2x.%@", name.pathExtension]];
            } else {
                name = [name stringByAppendingString:@"-568h@2x"];
            }
            
            //load the image e.g from disk or cache
            UIImage *image = [UIImage imageNamed: name ];
            if (image) {
                //strange Bug in iOS, the image name have a "@2x" but the scale isn't 2.0f
                return [UIImage imageWithCGImage: image.CGImage scale:2.0f orientation:image.imageOrientation];
            }
        }
    }
    
    return [UIImage imageNamed: name ];
}

// Formats the photo.
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize {
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = (CGBitmapInfo) kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    }
    
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, M_PI_2); // + 90 degrees
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, -M_PI_2); // - 90 degrees
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, -M_PI); // - 180 degrees
    }
    
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return newImage; 
}

// This only exists so that we can record an event in server when the user presses the 'back' button.
- (void)willMoveToParentViewController:(UIViewController *)parent{
    if(!parent){
        [self saveMetrics:@"Photos_BackButtonClicked"];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}

- (IBAction)showAdditionImage:(id)sender {
    [self saveMetrics:@"Photos_AdditionalPhotos_ButtonClicked"];
    ANAdditionalImageViewController *additionImageController = [[ANAdditionalImageViewController alloc] initWithNibName:@"ANAdditionalImageViewController"];
    additionImageController.claim = self.claim;
    [self presentViewController:additionImageController animated:YES completion:nil];
}

- (IBAction)continueClicked:(UIButton *)sender {
    [self saveMetrics:@"Photos_Next_ButtonClicked"];
    NSMutableArray *filePaths = [[NSMutableArray alloc]init];
    [filePaths addObject:[self fileNameFromImageEnum:damageLeft]];
    [filePaths addObject:[self fileNameFromImageEnum:damageCenter]];
    [filePaths addObject:[self fileNameFromImageEnum:damageRight]];
    [filePaths addObject:[self fileNameFromImageEnum:vin]];
    [filePaths addObject:[self fileNameFromImageEnum:odometer]];
    [filePaths addObject:[self fileNameFromImageEnum:leftFront]];
    [filePaths addObject:[self fileNameFromImageEnum:leftRear]];
    [filePaths addObject:[self fileNameFromImageEnum:rightRear]];
    [filePaths addObject:[self fileNameFromImageEnum:rightFront]];
    
    BOOL allPhotosTaken = YES;
    for (NSString *filePath in filePaths) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Need All Photos" message:@"Please capture all of the photos and press Continue." delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
            alertView.tag = 1;
            [alertView show];
            allPhotosTaken = NO;
            break;
        }
    }
    
    if (allPhotosTaken) {
        [self updateClaimStatus:ANCustomerStatusPhotos];
        ANSubmitViewController *submitImageController = [[ANSubmitViewController alloc] initWithNibName:@"ANSubmitViewController"];
        submitImageController.claim = self.claim;
        [self.navigationController pushViewController:submitImageController animated:YES];
    }
}

-(UIImage*) getPhotoReturnOverlayImage: (ANPhotoAngle) angle {
    NSString *imageName;
    
    switch (angle) {
        case damageLeft:
            imageName = @"damage_photo_left_return";
            break;
        case damageCenter:
            imageName = @"damage_photo_center_return";
            break;
        case damageRight:
            imageName = @"damage_photo_right_return";
            break;
        case vin:
            imageName = @"vehicle_photo_vin_return";
            break;
        case odometer:
            imageName = @"vehicle_photo_odometer_return";
            break;
        case leftFront:
            imageName = @"vehicle_photo_left_front_return";
            break;
        case leftRear:
            imageName = @"vehicle_photo_left_rear_return";
            break;
        case rightRear:
            imageName = @"vehicle_photo_right_rear_return";
            break;
        case rightFront:
            imageName = @"vehicle_photo_right_front_return";
            break;
        default:
            return nil;
    }
    
    NSString *deviceModel = [self.globalInstance deviceModelName];
    if([deviceModel hasPrefix:@"iPhone 4"]) {
        imageName = [NSString stringWithFormat:@"%@.bundle/%@_iphone4.png", AUDAEXPLORE_GTD_BUNDLE, imageName];
    } else {
        imageName = [NSString stringWithFormat:@"%@.bundle/%@.png", AUDAEXPLORE_GTD_BUNDLE, imageName];
    }
    
    UIImage *overlay = [UIImage imageNamed:imageName];
    
    return overlay;
}

+ (UIImage*)cropImage:(UIImage*)image toSizeScale:(CGSize)toSize {
    UIImage *result = image;
    CGSize sourceSize = image.size;
    CGFloat scale, newWidth, newHeight;
    CGRect cropRect;
    
    //if the source image is portrait...retain the width of the source image
    //calculate the new height
    if( sourceSize.height > sourceSize.width) { //portrait...retain the width
        scale = sourceSize.width / toSize.width;
        newWidth = sourceSize.width;
        newHeight = toSize.height * scale;
        
        CGFloat verticalOffset = (sourceSize.height - newHeight) / 2;
        cropRect = CGRectMake(0, verticalOffset, newWidth, newHeight);
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
        result = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    } else {
        //if the source image is landscape or square...retain the height
        //of the source image and calculate the new width
        scale = sourceSize.height / toSize.height;
        newHeight = sourceSize.height;
        newWidth = toSize.width * scale;
        
        CGFloat horizontalOffset = (sourceSize.width - newWidth) / 2;
        cropRect = CGRectMake(horizontalOffset, 0, newWidth, newHeight);
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
        result = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    
    return result;
}

@end
