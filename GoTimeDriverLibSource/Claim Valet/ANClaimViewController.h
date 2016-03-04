//
//  ANClaimViewController.h
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/13/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaim.h"
#import <LoopBack/LoopBack.h>
#import "ANUtils.h"
#import "ANGlobal.h"

@interface ANClaimViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *currentTextField;

@property (strong, nonatomic) ANClaim *claim;
@property (strong, nonatomic) ANGlobal *globalInstance;
@property (nonatomic, strong) NSString *metricPrefix;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil;

- (void) updateClaimStatus: (ANCustomerStatus) status;
- (NSString*) getGraphicsPath;
- (NSString*) getDocumentsPath;
- (NSURL*) getCarDirectoryURL;
- (NSURL*) getMasksDirectoryURL;
- (NSString*) imageNameFromEnum: (ANPhotoAngle) angle;
- (NSString *)fileNameFromImageEnum:(ANPhotoAngle) photoAngle;
- (NSDictionary*) getAllFilePathsToUpload;
- (NSString*)getEstimateFilePath;
- (void) saveMetrics:(NSString *)event;
- (BOOL) connectedToInternet;
- (void)showNotConnectedToInternetAlert;
- (void) saveClaimToServer;
- (void) returnToHostApp;
- (void)showAlertMessage:(NSString *) message withTitle:(NSString*) title;
- (void) cancelClicked;

- (NSMutableDictionary*)getInstallationParams;
-(void) createOrUpdateInstallation:(NSDictionary*) parameters;
- (void)updateCurrentInstallation:(NSDictionary *)parameters;
- (void) getConfigurationsFromMBE;
- (void)showNotConnectedToMBEAlert:(BOOL)bExit;
- (BOOL)connectedToMBE:(NSError*)error;
- (void) showErrorAlert:(NSString *)message withTitle:(NSString *)title exit:(BOOL)backToHost;
- (void) sendCustomerStatusToHostApp;
-(void) deleteUserPhotos;
-(void)persistClaimStatusLocally:(NSString *)claimNumber withMessage:(NSString *)msg;
-(BOOL) isiPad;
@end
