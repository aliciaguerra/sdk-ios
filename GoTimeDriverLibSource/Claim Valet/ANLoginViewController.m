//
//  ANLoginViewController.m
//  Self-ServiceEstimateDriver
//
//  Created by Quan Nguyen on 8/10/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANLoginViewController.h"
#import "ANThankYouViewController.h"
#import "ANWelcomeViewController.h"
#import "AEVehicleInfoViewController.h"
#import "ANWelcomeTextVehicleIdentifiedVC.h"
#import "ANWelcomeTextVehicleNotIdentifiedVC.h"

@interface ANLoginViewController ()

@property (strong, nonatomic) IBOutlet UILabel *lblClaimNumber;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSString *claimNumber;

@end

@implementation ANLoginViewController
@synthesize lblClaimNumber;
@synthesize claimNumber;


- (ANLoginViewController *)initWithClaimJson:(NSData *)claimJson {
    self = [super initWithNibName:@"ANLoginViewController"];
    if (self) {
        self.globalInstance = [ANGlobal getGlobalInstance];
        
        //only do these MBE things if we have internet connection
        //do not display the error message here, since the view controller
        //is not in the navigation hierarchy yet.  We delay the error message until
        //viewDidAppear
        if([self connectedToInternet]) {
            [self getConfigurationsFromMBE];
            [self createOrUpdateInstallation:[self getInstallationParams]];
        }
        
        NSError * error = nil;
        NSDictionary * claimData = [NSJSONSerialization JSONObjectWithData:claimJson
                                                                   options:kNilOptions
                                                                     error:&error];
        claimNumber = [claimData valueForKey:@"claimNumber"];
        
        NSString *videoInstruction = [claimData valueForKey:@"videoInstruction"];
        if( videoInstruction != nil && ([videoInstruction caseInsensitiveCompare:@"no"] == NSOrderedSame) ) {
            self.globalInstance.bVideoInstruction = NO;
        } else {
            self.globalInstance.bVideoInstruction = YES;
        }
        
        NSString *lmPhotoLocationRequired = [claimData valueForKey:@"photoLocationRequired"];
        if( lmPhotoLocationRequired != nil && ([lmPhotoLocationRequired caseInsensitiveCompare:@"no"] == NSOrderedSame) ) {
            self.globalInstance.bLMPhotoLocationRequired = NO;
        } else {
            self.globalInstance.bLMPhotoLocationRequired = YES;
        }
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.globalInstance setNavCon:(ANNavigationController *)self.navigationController];
    
    //if there's no internet connection on this login screen, display error and return to host app
    //because we cannot proceed any further.
    if( ! [self connectedToInternet]) {
        NSString *errorMessage = @"This action requires access to the internet. Please verify your connection, and/or device settings.";
        
        self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_ERROR_CANNOT_CONNECT_TO_SERVER;
        self.globalInstance.errorDescription = errorMessage;
        
        [self showErrorAlert:errorMessage
                   withTitle:@"No Internet Connection"
                        exit:YES];
    } else {
        if(claimNumber == nil || [claimNumber isEqualToString:@""]) {
            [self showErrorAlert:@"No claim number provided." withTitle:@"Error" exit:YES];
        } else {
            self.lblClaimNumber.text = claimNumber;
            [self getClaimFromMBE:claimNumber];
        }
    }
}

-(void) getClaimFromMBE:(NSString *)strClaimNumber {
    NSMutableDictionary *claimInfo = [[NSMutableDictionary alloc] init];
    [claimInfo setObject:strClaimNumber forKey:@"claimNumber"];
    [claimInfo setObject:ORGID_VALUE forKey:@"orgId"];
    
    [self.globalInstance.loopBackAPIHelper callMobileBackEnd:CLAIM_DATA_MODEL_NAME
                                                  methodName:@"findClaimByOrgId"
                                                  parameters:claimInfo
                                                     success:^(id value) {
                                                        NSDictionary *claimDictionary = [value valueForKey:@"claim"];
                                                        if (claimDictionary) {
                                                            NSDictionary *parametersForInstallation = @{@"claim_objectId" : [claimDictionary valueForKey:@"id"]};
                                                            [self updateCurrentInstallation:parametersForInstallation];
                                                            [self getClaimFromDictionary:claimDictionary];
                                                            
                                                        } else {
                                                            [self saveMetrics:@"Welcome_PageLoadFailed_ClaimUnavailable"];
                                                            self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                            self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                            NSString *errorMsg = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                            [self showErrorAlert:errorMsg withTitle:@"Unable to Locate Claim" exit:YES];
                                                        }
                                                        [self.spinner stopAnimating];
                                                     }
                                                     failure:^(NSError *error) {
                                                         if( ! [self connectedToMBE:error]) {
                                                             [self saveMetrics:@"Welcome_PageLoadFailed_CannotConnect"]; //like it ever gets to the server
                                                             [ANUtils errorHandle:error withLogMessage:@"Cannot connect to server to get claim"];
                                                             [self showNotConnectedToMBEAlert:YES];
                                                         } else {
                                                             [self saveMetrics:@"Welcome_PageLoadFailed_ClaimUnavailable"];
                                                             self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                             self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                             NSString *errorMsg = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST;
                                                             [self showErrorAlert:errorMsg withTitle:@"Unable to Locate Claim" exit:YES];
                                                         }
                                                         [self.spinner stopAnimating];
                                                     }];
}

- (void)getClaimFromDictionary:(NSDictionary*) dictionary {
    self.claim = [[ANClaim alloc]initWithNSDictionary:dictionary];
    [self getBodyStyleFromServer];
}
-(void)showThankYouViewController
{
    ANThankYouViewController *viewController = [[ANThankYouViewController alloc] initWithNibName:@"ANThankYouViewController"];
    viewController.claim = self.claim;
    [self.navigationController pushViewController:viewController animated:YES];
}
- (void)getBodyStyleFromServer
{
    self.claim.clipCode = [ANUtils getBodyStyleFromServerForFileID:self.claim.fileID andStyleModel:self.claim.styleID];
    if (self.claim.customerStatus == ANCustomerStatusSubmitted) {
        [self.spinner stopAnimating];
        [self saveMetrics:@"Welcome_PageLoadFailed_AlreadyCompleted"];
        
        self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_ERROR_ALREADY_COMPLETED;
        self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_ALREADY_COMPLETED;
        NSString *errorMsg = DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_ALREADY_COMPLETED;
        [self showErrorAlert:errorMsg withTitle:@"Self-Service Estimate Already Completed" exit:YES];
    } else {
        [self deleteUserPhotos];
        [self persistClaimStatusLocally:self.claim.claimNumber withMessage:@"Self-Service Estimate not completed."];
        //video instruction
        if([self.globalInstance damageViewerEnabled] && self.globalInstance.bVideoInstruction ) {
            if (self.claim.yearMakeModel.length > 0) {
                ANWelcomeViewController *viewController;
                if ([UIScreen mainScreen].bounds.size.height == 480) {
                    viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified4"];
                } else {
                    viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified"];
                }
                viewController.navigationItem.hidesBackButton = YES;
                viewController.claim = self.claim;
                viewController.bShouldDownloadGraphic = YES;
                [self.navigationController pushViewController:viewController animated:YES];
            } else {
                AEVehicleInfoViewController *viewController;
                if ([UIScreen mainScreen].bounds.size.height == 480) {
                    viewController = [[AEVehicleInfoViewController alloc] initWithNibName:@"AEVehicleInfoViewController4"];
                } else {
                    viewController = [[AEVehicleInfoViewController alloc] initWithNibName:@"AEVehicleInfoViewController"];
                }
                viewController.navigationItem.hidesBackButton = YES;
                viewController.claim = self.claim;
                [self.navigationController pushViewController:viewController animated:YES];
            }
        } else {    //text instruction
            if (self.claim.yearMakeModel.length > 0) {
                ANWelcomeTextVehicleIdentifiedVC *viewController;
                if ([UIScreen mainScreen].bounds.size.height == 480) {
                    viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC4"];
                } else {
                    viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC"];
                }
                viewController.navigationItem.hidesBackButton = YES;
                viewController.claim = self.claim;
                viewController.bShouldDownloadGraphic = YES;
                [self.navigationController pushViewController:viewController animated:YES];
            } else {
                ANWelcomeTextVehicleNotIdentifiedVC *viewController;
                if ([UIScreen mainScreen].bounds.size.height == 480) {
                    viewController = [[ANWelcomeTextVehicleNotIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleNotIdentifiedVC4"];
                } else {
                    viewController = [[ANWelcomeTextVehicleNotIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleNotIdentifiedVC"];
                }
                viewController.navigationItem.hidesBackButton = YES;
                viewController.claim = self.claim;
                viewController.bShouldDownloadGraphic = NO;
                [self.navigationController pushViewController:viewController animated:YES];
            }
        }
    }
}

@end
