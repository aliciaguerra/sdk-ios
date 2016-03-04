//
//  ANCameraViewController.m
//  Claim Valet
//
//  Created by Tung Hoang on 3/19/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import "ANCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ANCameraPreviewView.h"
#import "ToastView.h"
#import <CoreLocation/CoreLocation.h>
#import "ANConfirmPhotoViewController.h"
#import "ANGlobal.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface ANCameraViewController () {
    UIImage *overlayImage;
    ANPhotoAngle photoAngle;
    CLLocationManager *locationManager;
    CLLocation *location;
    BOOL bLocationServAvailableForApp;
}

// For use in the storyboards.
@property (nonatomic, weak) IBOutlet ANCameraPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIImageView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *btnWhereIsMyVin;
@property (weak, nonatomic) IBOutlet UIButton *btnWhereIsMyVinClose;
@property (weak, nonatomic) IBOutlet UIView *toolBar;
@property (strong, nonatomic) IBOutlet UIImageView *imgTextBackground;

- (IBAction)captureImage:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

@end

@implementation ANCameraViewController

@synthesize motionManager;

- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if([self.globalInstance requirePhotoLocation]) {
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
    } else {
        bLocationServAvailableForApp = NO;
    }

	motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1;
    
    [self startMotion];
    
    _overlayView.backgroundColor = [UIColor clearColor];
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];
	
	// Setup the preview view
	[[self previewView] setSession:session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [ANCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
            
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                AVCaptureVideoPreviewLayer *avLayer = (AVCaptureVideoPreviewLayer *)[[self previewView] layer];
				[[avLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)[self preferredInterfaceOrientationForPresentation]];
                
                CGRect bounds=self.previewView.layer.bounds;
                avLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                avLayer.bounds=bounds;
                avLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
			});
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
	});
}


- (void)viewWillAppear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		
		__weak ANCameraViewController *weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
			ANCameraViewController *strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf session] startRunning];
			});
		}]];
		[[self session] startRunning];
	});
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //the image view may have changed size...resize the overlay image to fill it.
    if (overlayImage != nil) {
        NSLog(@"Image width %0.2f, height %0.2f", overlayImage.size.width, overlayImage.size.height);
        
        CGSize size = self.overlayView.frame.size;
        UIGraphicsBeginImageContext(size);
        [overlayImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        overlayImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self.overlayView setImage:overlayImage];
        if (photoAngle == vin) {
            [self.btnWhereIsMyVin setHidden:NO];
        } else {
            [self.btnWhereIsMyVin setHidden:YES];
        }
    }
}

- (IBAction)showWhereIsVin:(id)sender {
    [self saveMetrics:@"PhotoCamera_WhereIsMyVIN_ButtonClicked"];
    
    NSString *imgPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VINa.png", AUDAEXPLORE_GTD_BUNDLE];
    if (  ([UIScreen mainScreen].bounds.size.width == 480)
        || ([self isiPad]) ){
        imgPath = [NSString stringWithFormat:@"%@.bundle/Where-is-my-VIN-iPhone4a.png", AUDAEXPLORE_GTD_BUNDLE];
    }
    UIImage *whereVIN= [UIImage imageNamed:imgPath];
    
    //resize image for ipad
    if([self isiPad]) {
        CGSize size = self.view.frame.size;
        UIGraphicsBeginImageContext(size);
        [whereVIN drawInRect:CGRectMake(0, 0, size.width, size.height)];
        whereVIN = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    [self.overlayView setImage:whereVIN];

    [self.btnWhereIsMyVin setHidden:YES];
    [self.btnWhereIsMyVinClose setHidden:NO];
    [self.toolBar setHidden:YES];
    [self.imgTextBackground setHidden:YES];
    
    [motionManager stopDeviceMotionUpdates];
}

- (IBAction)closeWhereIsVin:(id)sender {
    [self.overlayView setImage:overlayImage];
    [self.btnWhereIsMyVin setHidden:NO];
    [self.btnWhereIsMyVinClose setHidden:YES];
    [self.toolBar setHidden:NO];
    [self.imgTextBackground setHidden:NO];
    
    [self startMotion];
}

- (void)startMotion {
    [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        CMAcceleration userAcceleration = motion.userAcceleration;
        
        if (fabs(userAcceleration.x) > 0.021 || fabs(userAcceleration.y) > 0.021 || fabs(userAcceleration.z) > 0.021) {
            [ToastView showToastInParentView:self.overlayView withText:@"Hold Steady" withDuaration:1.0];
        }
        
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			[self runStillImageCaptureAnimation];
		}
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRunning)
			{
				[[self cameraButton] setEnabled:YES];
				[[self cancelButton] setEnabled:YES];
			}
			else
			{
				[[self cameraButton] setEnabled:NO];
				[[self cancelButton] setEnabled:NO];
			}
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (IBAction)cancel:(id)sender {
    [self saveMetrics:@"PhotoCamera_Cancel_ButtonClicked"];
    
    if (_delegate != nil)
        [_delegate cancelCapturing];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)captureImage:(id)sender
{
    [self saveMetrics:@"PhotoCamera_Take_ButtonClicked"];
    
	dispatch_async([self sessionQueue], ^{
		// Update the orientation on the still image output video connection before capturing.
		[[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
		
		// Flash set to Auto for Still Capture
		[ANCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
		
		// Capture a still image.
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			
			if (imageDataSampleBuffer)
			{
				NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
				UIImage *image = [[UIImage alloc] initWithData:imageData];
                
                // Display confirm photo screen. If user selects Retake, then dismiss confirm photo screen back to camera view.
                // If user selects Use, then dismiss confirm photo screen and call delegate's onCaptureImage.
                
                if ([self.globalInstance requirePhotoLocation] && bLocationServAvailableForApp) {
                    [self.globalInstance.photoLocations setObject:location forKey:[self imageNameFromEnum:photoAngle]];
                }
                
                ANConfirmPhotoViewController *confirmPhotoViewController = [[ANConfirmPhotoViewController alloc] initWithNibName:@"ANConfirmPhotoViewController"];
                
                confirmPhotoViewController.delegate = _delegate;
                confirmPhotoViewController.photoImage = image;
                confirmPhotoViewController.claim = self.claim;
                
                [self presentViewController:confirmPhotoViewController animated:NO completion:nil];
			}
		}];
	});
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoDeviceInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

- (void) setOverlayImage:(UIImage *) image {
    overlayImage = image;
}

- (void) setPhotoAngle:(ANPhotoAngle) iPhotoAngle {
    photoAngle = iPhotoAngle;
}

#pragma mark UI

- (void)runStillImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[[self previewView] layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[[self previewView] layer] setOpacity:1.0];
		}];
	});
}

- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			//Granted access to mediaType
			[self setDeviceAuthorized:YES];
		}
		else
		{
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCam!"
											message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}

-(NSString*) imageNameFromEnum: (ANPhotoAngle) angle
{
    if (angle == leftFront) {
        return @"leftFront.jpg";
    } else if (angle == leftRear) {
        return @"leftRear.jpg";
    } else if (angle == rightRear) {
        return @"rightRear.jpg";
    } else if (angle == rightFront) {
        return @"rightFront.jpg";
    } else if (angle == odometer) {
        return @"odometer.jpg";
    } else if (angle == vin) {
        return @"vin.jpg";
    } else if (angle == damageRight) {
        return @"damageRight.jpg";
    } else if (angle == damageCenter) {
        return @"damageCenter.jpg";
    } else if (angle == damageLeft) {
        return @"damageLeft.jpg";
    } else if (angle == additionalnumberone) {
        return @"addphoto1.jpeg";
    } else if (angle == additionalnumbertwo) {
        return @"addphoto2.jpeg";
    } else if (angle == additionalnumberthree) {
        return @"addphoto3.jpeg";
    } else if (angle == additionalnumberfour) {
        return @"addphoto4.jpeg";
    } else if (angle == additionalnumberfive) {
        return @"addphoto5.jpeg";
    } else if (angle == additionalnumbersix) {
        return @"addphoto6.jpeg";
    }
    return @"";
}

#pragma mark - Core Location delegate methods

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Location updated");
    CLLocation *newLocation = [locations lastObject];
    CLLocation *oldLocation;
    if (locations.count > 1) {
        oldLocation = [locations objectAtIndex:locations.count-2];
    } else {
        oldLocation = nil;
    }
    location = newLocation;
    NSLog(@"didUpdateToLocation %@ from %@", newLocation, oldLocation);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        location = [[CLLocation alloc] initWithLatitude:locationManager.location.coordinate.latitude longitude:locationManager.location.coordinate.longitude];
        NSLog(@"Location %f", location.coordinate.latitude);
        bLocationServAvailableForApp = YES;
        if ( [self.globalInstance requirePhotoLocation] && [CLLocationManager locationServicesEnabled]) {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            locationManager.distanceFilter = 1.0f;
            [locationManager startUpdatingLocation];
        }
    } else {
        bLocationServAvailableForApp = NO;
    }
}

@end
