//
//  ANSubmitViewController.m
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 8/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANSubmitViewController.h"
#import "ANThankYouViewController.h"
#import <CoreLocation/CoreLocation.h>
#define MAX_LENGTH 2000
@interface ANSubmitViewController () {
    NSMutableSet *filesUploaded;
    bool isUploaded;
    MBProgressHUD *HUD;
    bool alertShowing;
    CGFloat animatedDistance;
    UIImage *imgTitleBackground;
}

@property (weak, nonatomic) IBOutlet UIImageView *imgBlue;

@end

@implementation ANSubmitViewController

@synthesize imgBlue;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.metricPrefix = @"ClaimNotes";
    [self saveMetrics:@"ClaimNotes_PageLoaded"];
    
    self.addNoteTextView.delegate = self;
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    
    [self setNoteLookAndFeel];
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void) setNoteLookAndFeel {
    [self.addNoteTextView.layer setBorderColor:[[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.addNoteTextView.layer setBorderWidth:1.0];
    self.addNoteTextView.clipsToBounds = YES;
}

- (void)hideKeyBoard {
    [self.addNoteTextView resignFirstResponder];
}

- (IBAction)submit:(id)sender {
    [self saveMetrics:@"ClaimNotes_Submit_ButtonClicked"];
    
    if (![self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
    if (self.claim.customerStatus < ANCustomerStatusPhotos) {
        [self updateClaimStatus:ANCustomerStatusPhotos];
    }
    
    [self performPhotosSubmission];
}

- (void) performPhotosSubmission {
    
    filesUploaded = [[NSMutableSet alloc]init];
    isUploaded = NO;
    alertShowing = NO;
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.labelText = @"Submitting";
    HUD.detailsLabelText = @"0 %";
    HUD.delegate = self;
    
    NSDictionary *filePaths = [self getAllFilePathsToUpload];
    NSDictionary *photoLocations = self.globalInstance.photoLocations;
    int fileCount = 0;
    for (NSString *filename in filePaths) {
        NSString *filePath = [filePaths objectForKey:filename];
        if([[NSFileManager defaultManager]fileExistsAtPath:filePath]){
            fileCount++;
        }
    }
    
    NSMutableSet* tobeDeleted = [[NSMutableSet alloc] init];
    
    for (NSString *filename in filePaths) {
        NSMutableDictionary *attachmentObj =[[NSMutableDictionary alloc] init];
        NSString *attachmentType = @"UserUpload";
        if ([filename isEqualToString:@"statistic.txt"]) {
            attachmentType = @"StatisticFile";
            [attachmentObj setObject:@"text/txt" forKey:@"contentType"];
        } else {
            [attachmentObj setObject:[NSString stringWithFormat:@"image/%@",[filename pathExtension]] forKey:@"contentType"];
        }
        
        NSString *filePath = [filePaths objectForKey:filename];
        if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
            NSData *encryptedData = [[NSFileManager defaultManager] contentsAtPath:filePath];
            NSData *data = [self.globalInstance decrypt:encryptedData withKey:self.claim.claimNumber];
            NSString *base64String = [data base64EncodedStringWithOptions:0];
            
            [attachmentObj setObject:attachmentType forKey:@"attachmentType"];
            [attachmentObj setObject:filename forKey:@"fileName"];
            [attachmentObj setObject:base64String forKey:@"data"];
            if(self.claim.lbObject[@"userName"] != nil) {
                [attachmentObj setObject:self.claim.lbObject[@"userName"] forKey:@"userName"];
            }
            [attachmentObj setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] forKey:@"appName"];
            [attachmentObj setObject:ORGID_VALUE forKey:ORGID_KEY_NAME];
            [attachmentObj setObject:self.claim.claimNumber forKey:@"claimNumber"];
            if ([self.globalInstance requirePhotoLocation]) {
                CLLocation *photoLocation = [photoLocations valueForKey: filename];
                if (photoLocation) {
                    //Set Lat and Long for the photo
                    [attachmentObj setObject:[NSNumber numberWithDouble:photoLocation.coordinate.latitude] forKey:@"latitude"];
                    [attachmentObj setObject:[NSNumber numberWithDouble:photoLocation.coordinate.longitude] forKey:@"longitude"];
                }
            }
            NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
            [parameters setObject:attachmentObj forKey:@"parameters"];
            [[self.globalInstance loopBackAPIHelper] callMobileBackEnd:ATTACHMENT_MODEL_NAME methodName:@"uploadImage" parameters:parameters success:^(id value) {
                NSDictionary *respose = (NSDictionary*)value;
                                                           
                [filesUploaded addObject:filename];
                float progressPercent = 1.0f * [filesUploaded count] / fileCount;
                HUD.progress = progressPercent;
                
                HUD.labelText = @"Submitting";
                HUD.detailsLabelText = [NSString stringWithFormat:@"%.0f%%", progressPercent * 100];
                NSLog(@"Uploaded file %@ total uploaded files %ld of total files %lu progress percent %f",filename,(unsigned long)[filesUploaded count],(unsigned long)[filePaths count],progressPercent);
                
                if ([respose valueForKey:@"error"] == nil) {
                    [tobeDeleted addObject:filePath];
                }
                // If the last file has been uploaded then move to the Check Estimate controller
                if([filesUploaded count] == fileCount && !isUploaded){
                    isUploaded = YES;
                    [HUD hide:YES];
                    [self saveMetrics:@"ClaimNotes_Submit_Complete"];
                    
                    NSString *newClaimNodes = self.addNoteTextView.text;
                    //TODO nedd Verify it with MBE team.
                    if (newClaimNodes != nil && newClaimNodes.length > 0) {
                        [self.claim.lbObject setObject:newClaimNodes forKey:@"claimNote"];
                    }
                    
                    [self updateClaimStatus:ANCustomerStatusSubmitted];
                    
                    // Delete the uploaded file
                    for (NSString *deleteFile in tobeDeleted) {
                        [[NSFileManager defaultManager]removeItemAtPath:deleteFile error:nil];
                    }
                    
                    //store the claim status in NSUserDefaults
                    [self persistClaimStatusLocally:self.claim.claimNumber withMessage:@"Self-Service Estimate completed successfully"];
                    
                    //send the customer status to the host app
                    self.globalInstance.errorCode = SELF_SERVICE_ESTIMATE_SUCCESS;
                    self.globalInstance.errorDescription = DESCRIPTION_SELF_SERVICE_ESTIMATE_SUCCESS;
                    [self sendCustomerStatusToHostApp];
                    
                    ANThankYouViewController *viewController = [[ANThankYouViewController alloc] initWithNibName:@"ANThankYouViewController"];
                    viewController.claim = self.claim;
                    [self.navigationController pushViewController:viewController animated:YES];
                }
                
            } failure:^(NSError *error) {
                [HUD hide:YES];
                [ANUtils errorHandle:error withLogMessage:@"Can't upload images"];
                [self showUploadFailedAlert];
            }];
        }
    }
}

- (void)showUploadFailedAlert {
    if (!alertShowing) {
        alertShowing = YES;
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Upload Error" message:@"Files could not be uploaded, please check internet connection and submit again." delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange: range withString: text];
    if ([newText length]<= MAX_LENGTH) {
        return YES;
    }
    textView.text = [newText substringToIndex: MAX_LENGTH];
    return NO;
}

-(void) willMoveToParentViewController:(UIViewController *)parent {
    if (!parent) {
        [self saveMetrics:@"ClaimNotes_BackButtonClicked"];
    }
}

-(void)animateTextField:(UITextView*)textView up:(BOOL)up {
    const int movementDistance = -100; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? movementDistance : -movementDistance);
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self animateTextField:textView up:YES];
    [imgBlue setHidden:NO];
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [imgBlue setHidden:YES];
    [self animateTextField:textView up:NO];
    [textView resignFirstResponder];
}

@end
