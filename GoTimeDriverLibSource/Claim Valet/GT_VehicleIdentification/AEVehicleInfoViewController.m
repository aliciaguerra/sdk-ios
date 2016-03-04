//
//  AEVehicleInfoViewController.m
//  Gadget
//
//  Created by Silas Marshall on 7/3/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "AEVehicleInfoViewController.h"
#import "ANVehicleStyleMappingReader.h"
#import "SSZipArchive.h"
#import "ANPhotoViewController.h"
#import "GTDSEdmundsAEBodyStyle.h"
#import "GTDSSelectYearViewController.h"
#import "GTDSVINPortraitViewController.h"
#import "ANWelcomeViewController.h"
#import "ANUtils.h"
#import "AEScanVINZBarViewController.h"
#import "ANNavigationController.h"
#import "ANWelcomeTextVehicleIdentifiedVC.h"

@interface AEVehicleInfoViewController () {
    MBProgressHUD *HUD;
    NSMutableArray *tvStylesArr;
    NSMutableArray *fileIDsArr;
    NSMutableArray *styleIDsArr;
    
    NSString *styleIDstr;
    NSString *makeStr;
    NSString *modelStr;
    NSNumber *yearValue;
    
    NSMutableArray *bodyStyleDescriptionsArr;
    NSMutableArray *clipCodesArr;
    NSMutableArray *uniqueFileIDsArr;
    NSMutableArray *uniqueStyleIDsArr;
}

@property (nonatomic) BOOL isGraphicsDownloadComplete;
@property (nonatomic, strong) NSString *clipCodeStr;
@property (nonatomic, strong) NSString *vehicleDescriptionStr;

@property (nonatomic, strong) NSString *vinText;
@property (nonatomic, strong) NSString *fileIDStr;
@property (nonatomic, strong) UIAlertController *vinAlertControl;
@property (nonatomic, strong) UIAlertView *vinAlertView;
@property (retain, nonatomic) NSMutableData *receivedData;

@property (strong, nonatomic) IBOutlet UILabel *lblOwnerName;
@property (weak, nonatomic) IBOutlet UILabel *lblWelcome;
@property (strong, nonatomic) IBOutlet UILabel *lblLetStart;

- (IBAction)scanVIN:(id)sender;
- (IBAction)gotoSelectYear:(id)sender;
- (IBAction)vinEntryClicked:(id)sender;
- (IBAction)whereIsMyVINClicked:(id)sender;

@property (strong, nonatomic) IBOutlet UIImageView *edmundsLogo;
@end

@implementation AEVehicleInfoViewController

@synthesize isGraphicsDownloadComplete;
@synthesize clipCodeStr;
@synthesize vehicleDescriptionStr;
@synthesize vinText;
@synthesize edmundsLogo;
@synthesize fileIDStr;
@synthesize vinAlertView;
@synthesize vinAlertControl;
@synthesize lblOwnerName;
@synthesize lblLetStart;
@synthesize strLetStartText;
@synthesize strOwnerNameText;

typedef enum
	{
	kAE_VEHICLE_INFO_SECTION_DETAIL = 0,
	kAE_VEHICLE_INFO_SECTION_COUNT
	} AEVehicleInfoSection;

typedef enum
	{
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_VIN = 0,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_YEAR,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_MAKE,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_MODEL,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_STYLE,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_MILEAGE,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_ACTUAL_MILEAGE,
	kAE_VEHICLE_INFO_SECTION_DETAIL_ROW_COUNT
	} AEVehicleInfoSectionDetailRow;

#pragma mark - helpers

- (void)downloadVechicleVIN:(NSString *)vin {
    self.edmundsLogo.hidden = YES;
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"Processing VIN...";
    HUD.delegate = self;
    
    [self callVINDecodeService:vin];
}

-(void) callVINDecodeService:(NSString *) vin {
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    NSString *requestMessage = [ANWebServiceHelper getVINDecodeRequestMessage:vin];
    NSMutableURLRequest *theRequest = [ANWebServiceHelper getMessageRequest:requestMessage :self.globalInstance.ngpUsername :self.globalInstance.ngpPassword];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    [connection start];
}

//Add by James -- NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receivedData setLength: 0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

-(void)tryEdmundsVINDecode {
    NSLog(@"Try Edmunds VIN decode API");
    [self callEdmundsVinDecodeForVin:self.vinText];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Request Failed with following error: %@", error);
    [self tryEdmundsVINDecode];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    id result = [ANWebServiceHelper getJsonMessage:self.receivedData];
    
    if (result) {
        [self saveMetrics:@"VehicleIdentification_VINDecode_Autosource"];
        // we handle all three JSON formats possible in object below
        NSDictionary *object = result;
        
        if ([object valueForKey:@"Request"] != nil && [[object valueForKey:@"Request"] valueForKey:@"Error"] != nil) {
            NSLog(@"Error Message %@", [[object valueForKey:@"Request"] valueForKey:@"Message"]);
            [self tryEdmundsVINDecode];
            return;
        }
        
        NSLog(@"Main Dictionary: %@", [object description]);
        
        NSMutableArray *styles = [[NSMutableArray alloc] init];
        NSString *currentFileIDStr;
        
        NSLog(@"FileID %@", [object valueForKey:@"FileID"]);
        NSLog(@"Styles %@", [object valueForKey:@"Styles"]);
        
        NSMutableArray *currentStyles = nil;
        NSMutableDictionary *currentStyleDictionary = nil;
        
        if ([object valueForKey:@"Styles"] != nil) {
            currentStyles = [object valueForKey:@"Styles"];
            
            if ([currentStyles count] > 0) {
                currentStyleDictionary = [currentStyles objectAtIndex:0];
            }
        }
        
        // if FileID exists at top level of JSON, then we immediately retrieve it
        if (([object valueForKey:@"FileID"] == nil || [[object valueForKey:@"FileID"] isMemberOfClass:[NSNull class]])
           && ([object valueForKey:@"Styles"] == nil || (currentStyleDictionary != nil && [[currentStyleDictionary valueForKey:@"FileID"] isMemberOfClass:[NSNull class]]))) {
            [self tryEdmundsVINDecode];
            return;
        } else if ([object valueForKey:@"FileID"]) {
            currentFileIDStr = [object valueForKey:@"FileID"];
            [styles addObject:currentFileIDStr];
        } else {
            // otherwise, there should be a Styles key
            styles = [object valueForKey:@"Styles"];
        }
        
        NSLog(@"Styles Array: %@", [styles objectAtIndex:0]);
        
        // if Styles includes keys for "Results", then we get each dictionary within "Results"
        NSMutableArray *stylesWithinResultsArr = [[NSMutableArray alloc] init];
        for (NSDictionary *currentDictionary in styles) {
            if ([currentDictionary isKindOfClass:[NSDictionary class]] && [currentDictionary valueForKey:@"Results"])
            {
                NSMutableArray *currentResultsArr = [currentDictionary valueForKey:@"Results"];
                
                for (NSDictionary *resultsDictionary in currentResultsArr)
                {
                    [stylesWithinResultsArr addObject:resultsDictionary];
                }
            }
        }
        
        // if there are styles within the Results key
        if ([stylesWithinResultsArr count] > 0) {
            styles = [[NSMutableArray alloc] initWithArray:stylesWithinResultsArr];
        }
        
        makeStr = [object valueForKey:@"Make"];
        modelStr = [object valueForKey:@"Model"];
        yearValue = [object valueForKey:@"Year"];
        
        tvStylesArr = [[NSMutableArray alloc] init];
        fileIDsArr = [[NSMutableArray alloc] init];
        styleIDsArr = [[NSMutableArray alloc] init];
        
        // if FileID is at the top level of JSON, then we have only one fileID or styleID
        if ([object valueForKey:@"FileID"]) {
            [fileIDsArr addObject:[currentFileIDStr substringWithRange:NSMakeRange(0, 4)]];
            [styleIDsArr addObject:[currentFileIDStr substringWithRange:NSMakeRange(4, 2)]];
        } else {
            for (NSDictionary *currentDictionary in styles)
            {
                [tvStylesArr addObject:[currentDictionary objectForKey:@"Style"]];
                
                [fileIDsArr addObject:[[currentDictionary objectForKey:@"FileID"] substringWithRange:NSMakeRange(0, 4)]];
                [styleIDsArr addObject:[[currentDictionary objectForKey:@"FileID"] substringWithRange:NSMakeRange(4, 2)]];
            }
        }
        
        [self getBodyStyleDescriptions];
        
        fileIDStr = [uniqueFileIDsArr objectAtIndex:0];
        self.clipCodeStr = [clipCodesArr objectAtIndex:0];
        styleIDstr = [uniqueStyleIDsArr objectAtIndex:0];
        
        [self goBackToWelcome];
    } else {
        [self tryEdmundsVINDecode];
    }
}

- (void)processVIN:(NSString *)value {
    self.vinText = value;
    
    if (![self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
    if (![self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
	if (![value isEqualToString:@""]) {
		[self downloadVechicleVIN:value];
    }
}

- (IBAction)scanVIN:(id)sender {
    [self saveMetrics:@"VehicleIdentification_ScanVIN_ButtonClicked"];
    
    @try {
        AEScanVINZBarViewController *viewController = [[AEScanVINZBarViewController alloc] initWithNibName:@"AEScanVINZBarViewController"];
        viewController.delegate = self;
        viewController.claim = self.claim;
        ANNavigationController *navZBar = [[ANNavigationController alloc] initWithRootViewController:viewController];
        [navZBar setNavigationBarHidden:YES animated:YES];
        [self presentViewController:navZBar animated:YES completion:nil];
    } @catch (NSException *ex) {
        NSLog(@"Exception Description: %@", ex.description);
    }
}

- (NSString *)stringWebServiceEndpoint {
    return kAEInternetResourceAdaptor_WebServiceURL_Production;
}

#pragma mark - AEScanVINViewControllerDelegate

- (void)scanVINDidCancel {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)scanVINDidScan:(NSString *)value {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self processVIN:value];
}

#pragma mark - lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [self saveMetrics:@"VehicleIdentification_PageLoaded"];

    if (strOwnerNameText != nil) {
        lblOwnerName.textAlignment = NSTextAlignmentCenter;
        lblOwnerName.text = strOwnerNameText;
    } else {
        //set vehicle owner name
        NSString *strName = self.claim.ownerName;
        if (strName == nil || [strName isEqualToString:@""]) {
            strName = @"";
        } else {
            strName = [NSString stringWithFormat:@" %@", strName];
        }
        
        NSString *labelWelcomeText = [lblOwnerName text];
        labelWelcomeText = [labelWelcomeText stringByReplacingOccurrencesOfString:@"<ownerName>" withString:strName];
        lblOwnerName.text = labelWelcomeText;
    }
    
    if (strLetStartText != nil) {
        lblLetStart.text = strLetStartText;
    }
    
    self.isGraphicsDownloadComplete = NO;
    tvStylesArr = [[NSMutableArray alloc] init];
    
    self.edmundsLogo.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    if (self.globalInstance.isUsingEdmunds == YES) {
        self.edmundsLogo.hidden = NO;
    } else {
        self.edmundsLogo.hidden = YES;
    }
    
    NSLog(@"VehicleGraphicsDownloaded value: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"VehicleGraphicsDownloaded"]);
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

# pragma mark Text Field Delegates

- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)textEntered {
    if (textEntered.length != 0 && textField.text.length + textEntered.length == 17) {
        [self saveMetrics:@"VehicleIdentification_EnterVIN_Typed17Characters"];
        
        [textField resignFirstResponder];
        
        textField.text = [textField.text stringByAppendingString:textEntered];
        if ([UIAlertController class]) {
            [vinAlertControl dismissViewControllerAnimated:YES completion:nil];
        } else {
            [vinAlertView dismissWithClickedButtonIndex:0 animated:YES];
        }
        
        [self processVIN:textField.text];
    }
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

# pragma mark Orientation Methods

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void) getBodyStyleDescriptions {
    bodyStyleDescriptionsArr = [[NSMutableArray alloc] init];
    clipCodesArr = [[NSMutableArray alloc] init];
    uniqueFileIDsArr = [[NSMutableArray alloc] init];
    uniqueStyleIDsArr = [[NSMutableArray alloc] init];
    
    ANVehicleStyleMappingReader *bodyStyleDescReader = [[ANVehicleStyleMappingReader alloc] initClipCodeMappingsWithFile:@"BodyStyleDescription"];
    for (int index = 0; index < [fileIDsArr count]; ++index) {
        NSString *fileIDStr2 = [fileIDsArr objectAtIndex:index];
        NSString *styleIDstr2 = [styleIDsArr objectAtIndex:index];
        NSString *clipCodeStr2 = [ANUtils getBodyStyleFromServerForFileID:fileIDStr2 andStyleModel:styleIDstr2];
        if (clipCodeStr2 == nil) {
            clipCodeStr2 = @"";
        }

        BOOL isBodyStyleDuplicate = NO;
        
        for (int bodyStyleIndex = 0; bodyStyleIndex < [bodyStyleDescriptionsArr count]; ++bodyStyleIndex) {
            if ([[bodyStyleDescriptionsArr objectAtIndex:bodyStyleIndex] isEqualToString:[bodyStyleDescReader getBodyStyleDescriptionForClipCode:clipCodeStr2]] &&
                ![clipCodeStr2 isEqualToString:@""]) {
                isBodyStyleDuplicate = YES;
            }
        }
        
        if (isBodyStyleDuplicate == NO && ![clipCodeStr2 isEqualToString:@""]) {
            [bodyStyleDescriptionsArr addObject:[bodyStyleDescReader getBodyStyleDescriptionForClipCode:clipCodeStr2]];
            [clipCodesArr addObject:clipCodeStr2];
            [uniqueFileIDsArr addObject:fileIDStr2];
            [uniqueStyleIDsArr addObject:styleIDstr2];
        }
    }
}

- (void)callEdmundsVinDecodeForVin:(NSString *)vin {
    NSString *urlString = [NSString stringWithFormat:@"https://api.edmunds.com/api/vehicle/v2/vins/%@?fmt=json&api_key=32hj79x57h9s2w6fcjane5at", vin];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        self.edmundsLogo.hidden = NO;
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        long responseStatusCode = [httpResponse statusCode];
        if ((responseStatusCode == 200) && (data.length > 0) && (connectionError == nil)) {
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSDictionary *categoryEntries = [responseData objectForKey:@"categories"];
            NSString *vehicleStyle = [categoryEntries objectForKey:@"vehicleStyle"];
            NSString *numDoors = [responseData objectForKey:@"numOfDoors"];
            NSArray *years = [responseData objectForKey:@"years"];
            NSDictionary *yearItem = [years objectAtIndex:0];
            NSInteger year = [[yearItem objectForKey:@"year"] integerValue];
            yearValue = [[NSNumber alloc] initWithLong:year];
            NSDictionary *make = [responseData objectForKey:@"make"];
            NSString *makeName = [make objectForKey:@"name"];
            makeStr = makeName;
            NSDictionary *model = [responseData objectForKey:@"model"];
            NSString *modelName = [model objectForKey:@"name"];
            modelStr = modelName;
                                   
            GTDSEdmundsAEBodyStyle *edmundsAEMapper = [[GTDSEdmundsAEBodyStyle alloc] initClipCodeMappingsWithFile:@"Edmunds_AE_BodyStyles"];
            NSString *edmundsKey = [NSString stringWithFormat:@"%@%@", numDoors, vehicleStyle];
            edmundsKey = [edmundsKey stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSString *aeBodyStyle = [edmundsAEMapper getAEBodyStyleForEdmundsStyle:edmundsKey];
                                   
            fileIDStr = @"";
            self.clipCodeStr = @"";
            if (aeBodyStyle != nil) {
                self.clipCodeStr = aeBodyStyle;
            }
            [self saveMetrics:@"VehicleIdentification_VINDecode_Edmunds"];
            [self goBackToWelcome];
        } else {
            [HUD hide:YES];
            [self saveMetrics:@"VehicleIdentification_VINDecode_Unsuccessful"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"VIN provided cannot be decoded at this time. Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (IBAction)gotoSelectYear:(id)sender {
    [self saveMetrics:@"VehicleIdentification_SelectVehicle_ButtonClicked"];
    
    GTDSSelectYearViewController *viewController = [[GTDSSelectYearViewController alloc] initWithNibName:@"GTDSSelectYearViewController"];
    viewController.claim = self.claim;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)whereIsMyVINClicked:(id)sender {
    [self saveMetrics:@"VehicleIdentification_WhereIsMyVIN_ButtonClicked"];
    GTDSVINPortraitViewController *viewController = [[GTDSVINPortraitViewController alloc] initWithNibName:@"GTDSVINPortraitViewController"];
    
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Display Alert View with Textfield for VIN Entry
- (IBAction)vinEntryClicked:(id)sender {
    [self saveMetrics:@"VehicleIdentification_EnterVIN_ButtonClicked"];
    if ([UIAlertController class]) {
        __weak AEVehicleInfoViewController *self_ = self;
        vinAlertControl=   [UIAlertController
                            alertControllerWithTitle:@""
                            message:@"Please enter your VIN"
                            preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [self saveMetrics:@"VehicleIdentification_EnterVINCancel_ButtonClicked"];
                                                           [vinAlertControl dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        [vinAlertControl addAction:cancel];
        [vinAlertControl addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.delegate = self_;
            textField.autocapitalizationType =UITextAutocapitalizationTypeAllCharacters;
        }];
        [self presentViewController:vinAlertControl animated:YES completion:nil];
    } else {
        vinAlertView = [[UIAlertView alloc]initWithTitle:@"" message:@"Please enter your VIN" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        vinAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [vinAlertView textFieldAtIndex:0].delegate = self;
        [vinAlertView textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        [vinAlertView show];
    }
}


- (void) goBackToWelcome {
    self.claim.fileID = self.fileIDStr == nil ? @"" : self.fileIDStr;
    self.claim.clipCode = self.clipCodeStr == nil ? @"" : self.clipCodeStr;
    self.claim.yearMakeModel = [NSString stringWithFormat:@"%ld %@ %@", [yearValue longValue] , makeStr, modelStr];

    // Save vehicle information to the claim on Server.
    [self.claim.lbObject setObject:[NSString stringWithFormat:@"%d", yearValue.intValue] forKey:@"estimateVehicleYear"];
    [self.claim.lbObject setObject:makeStr forKey:@"estimateVehicleMake"];
    [self.claim.lbObject setObject:modelStr forKey:@"estimateVehicleModel"];
    [self.claim.lbObject setObject:(self.fileIDStr == nil || self.fileIDStr.length != 4 ? @"" : self.fileIDStr) forKey:@"vehicleFileId"];
    [self.claim.lbObject setObject:(styleIDstr == nil || styleIDstr.length != 2 ? @"" : styleIDstr ) forKey:@"vehicleStyleCode"];
    [self.claim.lbObject setObject:(vinText == nil ? @"" : vinText ) forKey:@"estimateVehicleVIN"];
    [self saveClaimToServer];
    
    [HUD hide:YES];
    
    NSString *welcomeText = @"Your vehicle has been identified";
    NSString *startButtonText = @"Continue";
    
    if ([self.globalInstance damageViewerEnabled] && self.globalInstance.bVideoInstruction) {
        ANWelcomeViewController *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified4"];
        } else {
            viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified"];
        }
        viewController.navigationItem.hidesBackButton = YES;
        viewController.bShouldDownloadGraphic = YES;
        viewController.claim = self.claim;
        viewController.strWelcomeText = welcomeText;
        viewController.strStartButtonText = startButtonText;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        ANWelcomeTextVehicleIdentifiedVC *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC4"];
        } else {
            viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC"];
        }
        viewController.navigationItem.hidesBackButton = YES;
        viewController.claim = self.claim;
        viewController.bShouldDownloadGraphic = YES;
        viewController.strWelcomeText = welcomeText;
        viewController.strStartButtonText = startButtonText;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer in the navigation stack.
        [self saveMetrics:@"VehicleIdentification_BackButtonClicked"];
        [self.navigationController.view.layer addAnimation:[ANUtils getTransitionFromLeft] forKey:nil];
    }
    [super viewWillDisappear:animated];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView == self.vinAlertView) {
        [self saveMetrics:@"VehicleIdentification_EnterVINCancel_ButtonClicked"];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ([self.strLetStartText isEqualToString:@""]) {
        CGRect startRect = self.lblLetStart.frame;
        CGRect ownerRect = self.lblOwnerName.frame;
        ownerRect.origin.y += (startRect.size.height / 2);
        self.lblLetStart.hidden = YES;
        self.lblOwnerName.frame = ownerRect;
     
        self.lblWelcome.hidden = YES;
    }
}
@end
