//
//  ANClaimViewController.m
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/13/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import "ANClaimViewController.h"
#import "ANNavigationController.h"
#import "ANClaim.h"

#define LOCAL_KEY @"Self-ServiceEstimateClaimStatus"

@interface ANClaimViewController () <UIActionSheetDelegate, UIAlertViewDelegate> {
    UIActionSheet *oldStyleActionSheet;
    UIAlertView *errorAlertView;
}

@property (nonatomic, strong) UIBarButtonItem *btnCancel;
@end

@implementation ANClaimViewController
@synthesize claim;
@synthesize currentTextField;
@synthesize globalInstance;
@synthesize metricPrefix;
@synthesize btnCancel;

- (instancetype)init {
    self = [super init];
    if (self) {
        globalInstance = [ANGlobal getGlobalInstance];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.globalInstance = [ANGlobal getGlobalInstance];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil {
    NSString *daNibName = nibNameOrNil;
    if ( [self isiPad] ) {
        daNibName = [NSString stringWithFormat:@"%@~ipad", nibNameOrNil];
    }
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:AUDAEXPLORE_GTD_BUNDLE withExtension:@"bundle"]];
    return [self initWithNibName:daNibName bundle:bundle];
}

- (void)viewDidLoad {
    btnCancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked)];
    self.navigationItem.rightBarButtonItem = btnCancel;
}

- (void)viewDidAppear:(BOOL)animated {
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    NSString *headerBG = [NSString stringWithFormat:@"%@.bundle/Header-BG.png", AUDAEXPLORE_GTD_BUNDLE];
    if([self isiPad]) {
        headerBG = [NSString stringWithFormat:@"%@.bundle/header-bg~ipad.png", AUDAEXPLORE_GTD_BUNDLE];
    }
    
    UIImage *imgBackground = [UIImage imageNamed:headerBG];
    [self.navigationController.navigationBar setBackgroundImage:imgBackground forBarMetrics:UIBarMetricsDefault];
    
    // Added to remove the 1px black line between the navigation bar and the view.
    self.navigationController.navigationBar.clipsToBounds = YES;
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (NSString*) getGraphicsPath {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* fullPathToFolder = [documentsDirectory stringByAppendingPathComponent:@"Car"];
    return fullPathToFolder;
}

- (NSString*) getDocumentsPath {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSURL*) getCarDirectoryURL {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* fullPathToFolder = [documentsDirectory stringByAppendingPathComponent:@"Car"];
    return [NSURL fileURLWithPath:fullPathToFolder];
}

- (NSURL*) getMasksDirectoryURL {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* fullPathToFolder = [documentsDirectory stringByAppendingPathComponent:@"Masks"];
    return [NSURL fileURLWithPath:fullPathToFolder];
}

- (void)updateClaimStatus: (ANCustomerStatus) status {
    self.claim.customerStatus = status;
    [self.claim.lbObject setObject:[NSNumber numberWithInt:status] forKey:@"customerStatus"];
    [self saveClaimToServer];
}

-(void)saveClaimToServer {
    [globalInstance.loopBackAPIHelper callMobileBackEnd:CLAIM_DATA_MODEL_NAME
                                            methodName:@"saveWithSuccess"
                                            parameters:self.claim.lbObject
                                               success:^(id value) {
                                                   NSLog(@"Save claim Success on the server");
                                               }
                                               failure:^(NSError *error) {
                                                   [ANUtils errorHandle:error withLogMessage:@"Can't update status claim to server."];
                                               }];
}

-(NSString*) imageNameFromEnum: (ANPhotoAngle) angle {
    if (angle == damageLeft) {
        return @"damageLeft.jpg";
    } else if (angle == damageCenter) {
        return @"damageCenter.jpg";
    } else if (angle == damageRight) {
        return @"damageRight.jpg";
    } else if (angle == vin) {
        return @"vin.jpg";
    } else if (angle == odometer) {
        return @"odometer.jpg";
    } else if (angle == leftFront) {
        return @"leftFront.jpg";
    } else if (angle == leftRear) {
        return @"leftRear.jpg";
    } else if (angle == rightRear) {
        return @"rightRear.jpg";
    } else if (angle == rightFront) {
        return @"rightFront.jpg";
    } else if (angle == dvLB) {
        return @"screen_shot_LB.jpeg";
    } else if (angle == dvLBheatmap) {
        return @"screen_shot_LB_heatmap.jpeg";
    } else if (angle == dvLT) {
        return @"screen_shot_LT.jpeg";
    } else if (angle == dvLTheatmap) {
        return @"screen_shot_LT_heatmap.jpeg";
    } else if (angle == dvRB) {
        return @"screen_shot_RB.jpeg";
    } else if (angle == dvRBheatmap) {
        return @"screen_shot_RB_heatmap.jpeg";
    } else if (angle == dvRT) {
        return @"screen_shot_RT.jpeg";
    } else if (angle == dvRTheatmap) {
        return @"screen_shot_RT_heatmap.jpeg";
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

- (NSString *)fileNameFromImageEnum:(ANPhotoAngle) photoAngle {
    NSString *fileName = [self imageNameFromEnum:photoAngle];
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* fullPathToFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    return fullPathToFile;
}

- (NSDictionary*) getAllFilePathsToUpload {
    NSArray *fileNames = [NSArray arrayWithObjects:[self imageNameFromEnum:damageLeft],[self imageNameFromEnum:damageCenter],[self imageNameFromEnum:damageRight],[self imageNameFromEnum:vin],[self imageNameFromEnum:odometer],[self imageNameFromEnum:leftFront],[self imageNameFromEnum:leftRear],[self imageNameFromEnum:rightRear],[self imageNameFromEnum:rightFront],[self imageNameFromEnum:dvLB],[self imageNameFromEnum:dvLBheatmap],[self imageNameFromEnum:dvLT],[self imageNameFromEnum:dvLTheatmap],[self imageNameFromEnum:dvRB],[self imageNameFromEnum:dvRBheatmap],[self imageNameFromEnum:dvRT],[self imageNameFromEnum:dvRTheatmap],[self imageNameFromEnum:additionalnumberone],[self imageNameFromEnum:additionalnumbertwo],[self imageNameFromEnum:additionalnumberthree],[self imageNameFromEnum:additionalnumberfour],[self imageNameFromEnum:additionalnumberfive],[self imageNameFromEnum:additionalnumbersix],@"statistic.txt",nil];
    
    NSMutableArray *arrayOfFiles = [[NSMutableArray alloc]init];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:damageLeft]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:damageCenter]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:damageRight]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:vin]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:odometer]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:leftFront]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:leftRear]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:rightRear]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:rightFront]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvLB]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvLBheatmap]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvLT]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvLTheatmap]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvRB]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvRBheatmap]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvRT]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:dvRTheatmap]];
    
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumberone]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumbertwo]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumberthree]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumberfour]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumberfive]];
    [arrayOfFiles addObject:[self fileNameFromImageEnum:additionalnumbersix]];
    
    [arrayOfFiles addObject:[[self getDocumentsPath] stringByAppendingPathComponent:@"statistic.txt"]];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:arrayOfFiles
                                                           forKeys:fileNames];
    return dictionary;
}


#pragma mark - Keyboard notifications
#define kOFFSET_FOR_KEYBOARD 200.0

-(void)keyboardWillShow {
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)sender {
    if ([sender isEqual:currentTextField])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

- (void)saveMetrics:(NSString *)event {
    NSMutableDictionary *parameters= [[NSMutableDictionary alloc] initWithDictionary:@{@"eventName" : event,
                                                                                       @"appName":[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
                                                                                       }];
    if (self.claim && self.claim.lbObject && self.claim.lbObject[@"id"]) {
        [parameters setObject:self.claim.lbObject[@"id"] forKey:@"claim_objectId"];
        [parameters setObject:self.claim.lbObject[@"orgId"] forKey:@"orgId"];
    }
    
    [globalInstance.loopBackAPIHelper callMobileBackEnd:@"MetricsDatas"
                                            methodName:@"saveWithSuccess"
                                            parameters:parameters
                                               success:^(id value) {
                                                   NSLog(@"Save MetricsDatas successful!.");
                                               } failure:^(NSError *error) {
                                                   [ANUtils errorHandle:error withLogMessage:@"Can't save MetricsDatas to server."];
                                               }];
}

- (BOOL)connectedToInternet {
    NSString* link = @"http://www.google.com";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:5];
    NSURLResponse* response=nil;
    NSError* error=nil;
    NSData* data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    return ( data != nil ) ? YES : NO;
}

- (void)showNotConnectedToInternetAlert {
    [self showAlertMessage:@"This action requires access to the internet. Please verify your connection, and/or device settings." withTitle:@"No Internet Connection"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) returnToHostApp {
    NSLog(@"return to host app");
    
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    //navigationControll == nil means presented modally
    if(topController.navigationController == nil ) {
        [topController dismissViewControllerAnimated:YES completion:nil];
    }

    [self.navigationController popToRootViewControllerAnimated:NO];
    
    UIViewController *daRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if(daRootVC.presentedViewController) {
        [daRootVC.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) cancelClicked {
    NSString *eventName = [NSString stringWithFormat:@"%@_Cancel_ButtonClicked", self.metricPrefix];
    [self saveMetrics:eventName];
    
    if ([UIAlertController class]) {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"This information has not been submitted. Are you sure you want to cancel?"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel Damage Capture"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self cancelDamageCapture];
                                                      }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Continue Damage Capture"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
        //handle differently for ipad
        if([self isiPad]) {
            actionSheet.popoverPresentationController.barButtonItem = self.btnCancel;
        }

        // Present action sheet.
        [self presentViewController:actionSheet animated:YES completion:nil];
    } else {
        oldStyleActionSheet = [[UIActionSheet alloc] initWithTitle:@"This information has not been submitted. Are you sure you want to cancel?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Continue Damage Capture"
                                             destructiveButtonTitle:nil otherButtonTitles: @"Cancel Damage Capture", nil];
        [oldStyleActionSheet showInView:self.view];
    }
}

-(void)showAlertMessage:(NSString *) message withTitle:(NSString*) title {
    if ([UIAlertController class]) {
        UIAlertController *alertView =   [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* close = [UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          [alertView dismissViewControllerAnimated:YES completion:nil];
                                                      }];
        [alertView addAction:close];
        [self presentViewController:alertView animated:YES completion:nil];
    } else {
        errorAlertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        errorAlertView.delegate = self;
        errorAlertView.tag = 0;
        [errorAlertView show];
    }
}

-(BOOL)shouldAutorotate{
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void) showErrorAlert:(NSString *)message withTitle:(NSString *)title exit:(BOOL)backToHost {
    if ([UIAlertController class]) {
        UIAlertController *errorController =   [UIAlertController alertControllerWithTitle:title
                                                                                   message:message
                                                                            preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [errorController dismissViewControllerAnimated:YES completion:nil];
                                                       if(backToHost) {
                                                           [self sendCustomerStatusToHostApp];
                                                           [self returnToHostApp];
                                                       }
                                                   }];
        [errorController addAction:ok];
        [self presentViewController:errorController animated:YES completion:nil];
    } else {
        errorAlertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        errorAlertView.delegate = self;
        errorAlertView.tag = (backToHost ? 1 : 0);
        [errorAlertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == errorAlertView) {
        if(errorAlertView.tag == 1) { //go back to host
            [self sendCustomerStatusToHostApp];
            [self returnToHostApp];
        }
    }
}

- (void)showNotConnectedToMBEAlert:(BOOL)bExit  {
    self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_ERROR_CANNOT_CONNECT_TO_SERVER;
    self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CANNOT_CONNECT_TO_SERVER;
    
    NSString *errorMsg = @"This action requires access to the internet. Please verify your connection, and/or device settings.";
    [self showErrorAlert:errorMsg withTitle:@"Unable to Connect to Server" exit:bExit];
}

-(BOOL)mbeRefusedConnection:(NSError*)error
{
    if(!([error.localizedRecoverySuggestion rangeOfString:@"ECONNREFUSED" options:NSCaseInsensitiveSearch].length==0)) {
        return YES;
    }
    
    return NO;
}

-(BOOL)connectedToMBE:(NSError*)error
{
    if (error != nil && (error.code == NSURLErrorSecureConnectionFailed || error.code == NSURLErrorBadServerResponse ||error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorTimedOut || [self mbeRefusedConnection:error])) {
        return NO;
    }
    return YES;
}

- (void) getConfigurationsFromMBE {
    [self.globalInstance.loopBackAPIHelper callMobileBackEnd:CONFIGURATION_MODEL_NAME
                                   methodName:@"findValuesByOrgId"
                                   parameters:@{@"orgId":ORGID_VALUE}
                                      success:^(id value) {
                                          NSArray *objects = (NSArray*)value;
                                          if (objects && objects.count >0) {
                                              [self.globalInstance setGlobalVariables:objects];
                                          } else {
                                              NSLog(@"Can't get Configurations from Server.");
                                          }
                                      }
                                      failure:^(NSError *error) {
                                          if (![self connectedToMBE:error]) {
                                              [ANUtils errorHandle:error withLogMessage:@"Cannot connect to server to get Configuration"];
                                              [self showNotConnectedToMBEAlert:YES];
                                          } else {
                                              [ANUtils errorHandle:error withLogMessage:@"Can not find Configuration."];
                                          }
                                      }];
}

-(NSMutableDictionary*)getInstallationParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[[UIDevice currentDevice] model] forKey:@"deviceMake"];
    [params setObject:[self.globalInstance deviceModelName] forKey:@"deviceModel"];
    [params setObject:[NSString stringWithFormat:@"%.1f", [[[UIDevice currentDevice] systemVersion] floatValue]] forKey:@"osVersion"];
    [params setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] forKey:@"appName"];
    [params setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"appId"];
    [params setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:@"appVersion"];
    [params setObject:@"ios" forKey:@"deviceType"];
    [params setObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"UUID"];
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"kDeviceTokenKey"];
    if (deviceToken) {
        [params setObject:deviceToken forKey:@"deviceToken"];
    }
    return params;
}

-(void) createOrUpdateInstallation:(NSDictionary*) parameters {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id installation_id =  [defaults objectForKey:@"installation_id"];
    
    if (installation_id) {
        [self updateCurrentInstallation:parameters];
    } else {
        [self saveInstallation:parameters];
    }
}

-(void)saveInstallation:(NSDictionary*)parameters {
    [self.globalInstance.loopBackAPIHelper callMobileBackEnd:INSTALLATIONS_MODEL_NAME
                              methodName:@"saveWithSuccess"
                              parameters:parameters
                                 success:^(id value) {
                                     LBModel *newInstallation = (LBModel*)value;
                                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                     [defaults setObject :newInstallation._id forKey:@"installation_id"];
                                     [defaults synchronize];
                                 } failure:^(NSError *error) {
                                     if( ! [self connectedToMBE:error]) {
                                         [self showNotConnectedToMBEAlert:YES];
                                     } else {
                                         NSLog(@"Failed to save Installation on Server.");
                                     }
                                 }];
}

- (void)updateCurrentInstallation:(NSDictionary *)parameters {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id installation_id =  [defaults objectForKey:@"installation_id"];
    if (installation_id) {
        [self.globalInstance.loopBackAPIHelper callMobileBackEnd:INSTALLATIONS_MODEL_NAME
                                  methodName:@"findById"
                                  parameters:@{@"id":installation_id}
                                     success:^(id value) {
                                         LBModel *installation = (LBModel*)value;
                                         for(NSString* key in [parameters allKeys]) {
                                             installation[key] = [parameters objectForKey:key];
                                         }
                                         installation[@"UUID"] =[[[UIDevice currentDevice] identifierForVendor] UUIDString];
                                         [self saveInstallation:installation.toDictionary];
                                     }
                                     failure:^(NSError *error) {
                                         if( ! [self connectedToMBE:error]) {
                                             [self showNotConnectedToMBEAlert:YES];
                                         } else {
                                             NSLog(@"Can't find installation on Server.");
                                         }
                                     }];
    }
}

-(void) deleteUserPhotos {
    NSDictionary *filePaths = [self getAllFilePathsToUpload];
    for (NSString *filename in filePaths) {
        NSString *filePath = [filePaths objectForKey:filename];
        if([[NSFileManager defaultManager]fileExistsAtPath:filePath]){
            [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
        }
    }
}

- (void) sendCustomerStatusToHostApp {
    ANNavigationController *navCon = (ANNavigationController *)[self.globalInstance getNavCon];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [result setObject:[NSNumber numberWithInt:self.globalInstance.errorCode] forKey:@"errorCode"];
    [result setObject:self.globalInstance.errorDescription  forKey:@"errorMsg"];
    [result setObject:[NSNumber numberWithInt:(int)self.claim.customerStatus] forKey:@"customerStatusCode"];
    [navCon.selfServiceEstimateDelegate backToHost:result];
}

-(void)persistClaimStatusLocally:(NSString *)claimNumber withMessage:(NSString *)msg {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *toPersist = nil;
    
    NSMutableDictionary *expressEstClaimStatusDictionary = [userDefaults objectForKey:LOCAL_KEY];
    if(expressEstClaimStatusDictionary == nil) {
        toPersist = [[NSMutableDictionary alloc] init];
    } else {
        toPersist = [expressEstClaimStatusDictionary mutableCopy];
    }
    
    [toPersist setObject:msg forKey:claimNumber];
    [userDefaults setObject:toPersist forKey:LOCAL_KEY];
    [userDefaults synchronize];
}

- (void)cancelDamageCapture {
    NSString *eventNameConfirmCancel = [NSString stringWithFormat:@"%@_CancelConfirm_ButtonClicked", self.metricPrefix];
    [self saveMetrics:eventNameConfirmCancel];
    
    //remove user photos from the device
    [self deleteUserPhotos];
    
    self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL;
    self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL;
    [self sendCustomerStatusToHostApp];
    [self returnToHostApp];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(actionSheet == oldStyleActionSheet) {
        if(buttonIndex == 0) { //cancel damage capture
            [self cancelDamageCapture];
        }
    }
}

- (BOOL) isiPad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end
