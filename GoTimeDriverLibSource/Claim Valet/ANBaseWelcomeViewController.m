//
//  ANBaseWelcomeViewController.m
//  Self-ServiceEstimateLib
//
//  Created by Quan Nguyen on 8/19/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANBaseWelcomeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3.h>
#import "SSZipArchive.h"
#import "MBProgressHUD.h"
#import "AEVehicleInfoViewController.h"
#import "ANWebGLPlaceHolderViewController.h"
#import "ANPhotoViewController.h"

@interface ANBaseWelcomeViewController () {
    MBProgressHUD *HUD;
    BOOL bGraphicsDownloadComplete;
    BOOL bDamageDownloadComplete;
}

@end

@implementation ANBaseWelcomeViewController

@synthesize bShouldDownloadGraphic;
@synthesize strWelcomeText;
@synthesize strStartButtonText;

- (instancetype)init {
    self = [super init];
    if (self) {
        strWelcomeText = nil;
        strStartButtonText = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.metricPrefix = @"Welcome";
    
    bGraphicsDownloadComplete = YES;
    bDamageDownloadComplete = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self saveMetrics: @"Welcome_PageLoaded"];

    //download the damage viewer code
    if([self.globalInstance damageViewerEnabled]) {
        [self downloadDamageFromS3];
    }
    
    // Get the vehicle graphics if the vehicle description is not blank.
    if (self.bShouldDownloadGraphic == YES) {
        [self downloadGraphicsFromS3];
        self.bShouldDownloadGraphic = NO;
    }
}

-(BOOL)hasDamageFolder {
    NSString* fullPathToFolder = [[self getDocumentsPath] stringByAppendingPathComponent:@"Damage/index.html"];
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPathToFolder];
}

-(BOOL)hasNewDamageFile:(NSDate *)remoteDate {
    NSString* fullPathToDamage = [[self getDocumentsPath] stringByAppendingPathComponent:@"Damage.zip"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPathToDamage]) {
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPathToDamage error:nil];
        NSDate *localDate = [attributes fileModificationDate];
        return [localDate compare:remoteDate] == NSOrderedAscending;
    } else {
        return YES;
    }
}

- (void)downloadingGraphicsFromBucket:(NSString *)bucket forAWSS3Object:(AWSS3Object *)summary  {
    // Download the graphics data.
    if (summary != nil) {
        NSString *zipPath = [[self getDocumentsPath] stringByAppendingPathComponent:@"Graphics.zip"];
        NSURL *downloadingFileURL = [NSURL fileURLWithPath:zipPath];
        
        // create our request
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = bucket;
        downloadRequest.key = summary.key;
        downloadRequest.downloadingFileURL = downloadingFileURL;
        bGraphicsDownloadComplete = NO;
        [self download:downloadRequest];
    } else {
        [self copyAndUnzip];
    }
}

- (void)download:(AWSS3TransferManagerDownloadRequest *)downloadRequest {
    switch (downloadRequest.state) {
        case AWSS3TransferManagerRequestStateNotStarted:
        case AWSS3TransferManagerRequestStatePaused: {
            downloadRequest.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (totalBytesExpectedToWrite > 0) {
                        HUD.progress = (float)((double) totalBytesWritten / totalBytesExpectedToWrite);
                    }
                });
            };
            
            AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
            [[transferManager download:downloadRequest] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    [self saveMetrics:@"VehicleDownloadUnsuccessful"];
                } else {
                    [self saveMetrics:@"VehicleDownloadSuccessful"];
                    
                    // Remove the existing graphics files.
                    NSError *error;
                    NSFileManager *fileMgr = [NSFileManager defaultManager];
                    NSString *carDirectory = [[self getDocumentsPath] stringByAppendingPathComponent:@"Car"];
                    if ([fileMgr removeItemAtPath:carDirectory error:&error] != YES) {
                        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
                    }
                    NSString *masksDirectory = [[self getDocumentsPath] stringByAppendingPathComponent:@"Masks"];
                    if ([fileMgr removeItemAtPath:masksDirectory error:&error] != YES) {
                        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
                    }
                    
                    NSString *zipPath = [[self getDocumentsPath] stringByAppendingPathComponent:@"Graphics.zip"];
                    NSString *destinationPath = [self getDocumentsPath];
                    
                    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]) {
                        NSLog(@"Unzip graphics successful!");
                        if ([self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:zipPath]] &&
                            [self addSkipBackupAttributeToItemAtURL:[self getCarDirectoryURL]] &&
                            [self addSkipBackupAttributeToItemAtURL:[self getMasksDirectoryURL]]) {
                            
                            bGraphicsDownloadComplete = YES;
                            
                            //if the damage viewer is already downloaded, dismiss the HUD now.
                            if(bDamageDownloadComplete) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [HUD hide:YES];
                                });
                            } else {
                                HUD.mode = MBProgressHUDModeIndeterminate;
                                HUD.labelText = @"Downloading damage viewer..";
                            }
                        }
                    } else {
                        NSLog(@"Unzip graphics NOT successful!");
                    }
                }
                return nil;
            }];
        }
            break;
        default:
            break;
    }
}

-(void) downloadDamageFromS3
{
    NSString *accessKey = self.globalInstance.accessKey;
    NSString *secretKey = self.globalInstance.secretKey;
    NSString *bucket = self.globalInstance.s3bucket;
    // Remove the existing damage files.
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:accessKey
                                                                                                      secretKey:secretKey];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSS3ListObjectsRequest *req = [AWSS3ListObjectsRequest new];
    req.bucket = bucket;
    req.delimiter = @"/";
    
    NSString *specificGraphicsPath = [NSString stringWithFormat:@"%@",@"Damage.zip"];
    req.prefix = specificGraphicsPath;
    
    [[s3 listObjects:req] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            AWSS3Object *summary = [listObjectsOutput.contents objectAtIndex:0];
            NSDate *remoteDate = summary.lastModified;
            if ([self hasNewDamageFile:remoteDate]) {
                [self downloadingDamageFromBucket:bucket forAWSS3Object:summary];
            }
        }
        return nil;
    }];
}


- (void)downloadingDamageFromBucket:(NSString *)bucket forAWSS3Object:(AWSS3Object *)summary
{
    if (summary != nil) {
        NSString *zipPath = [[self getDocumentsPath] stringByAppendingPathComponent:@"Damage.zip"];
        NSURL *downloadingFileURL = [NSURL fileURLWithPath:zipPath];
        
        // create our request
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = bucket;
        downloadRequest.key = summary.key;
        downloadRequest.downloadingFileURL = downloadingFileURL;
        bDamageDownloadComplete = NO;
        [self downloadDamage:downloadRequest];
    } else {
        [self copyAndUnzipDamage];
    }
}

- (void)copyAndUnzipDamage {
    NSString *zipPath = [[NSBundle mainBundle]pathForResource:@"Damage" ofType:@"zip"];
    NSString *destinationPath = [self getDocumentsPath];
    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath] ) {
        bDamageDownloadComplete = YES;
        //if the damage viewer is already downloaded, then dismiss the hud
        if(bDamageDownloadComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [HUD hide:YES];
            });
        }
    }
}

- (void)downloadDamage:(AWSS3TransferManagerDownloadRequest *)downloadRequest {
    switch (downloadRequest.state) {
        case AWSS3TransferManagerRequestStateNotStarted:
        case AWSS3TransferManagerRequestStatePaused: {
            
            AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
            [[transferManager download:downloadRequest] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    [self saveMetrics:@"DamageDownloadUnsuccessful"];
                } else {
                    [self saveMetrics:@"DamageDownloadSuccessful"];
                    NSString *zipPath = [[self getDocumentsPath] stringByAppendingPathComponent:@"Damage.zip"];
                    NSString *destinationPath = [self getDocumentsPath];
                    
                    if ([SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]) {
                        NSLog(@"Unzip damage successful!");
                        
                        bDamageDownloadComplete = YES;
                        
                        //if the graphics.zip is already downloaded, then dismiss the hud
                        if(bGraphicsDownloadComplete) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [HUD hide:YES];
                            });
                        }
                    } else {
                        NSLog(@"Unzip damage NOT successful!");
                    }
                }
                return nil;
            }];
        }
            break;
        default:
            break;
    }
}

- (void)downloadGraphicsFromS3
{
    NSString *accessKey = self.globalInstance.accessKey;
    NSString *secretKey = self.globalInstance.secretKey;
    NSString *bucket = self.globalInstance.s3bucket;
    
    // Remove the existing graphics files.
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *carDirectory = [[self getDocumentsPath] stringByAppendingPathComponent:@"Car"];
    if ([fileMgr removeItemAtPath:carDirectory error:&error] != YES) {
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    }
    NSString *masksDirectory = [[self getDocumentsPath] stringByAppendingPathComponent:@"Masks"];
    if ([fileMgr removeItemAtPath:masksDirectory error:&error] != YES) {
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    }
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:accessKey
                                                                                                      secretKey:secretKey];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                         credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSS3ListObjectsRequest *req = [AWSS3ListObjectsRequest new];
    req.bucket = bucket;
    req.delimiter = @"/";
    
    NSString *specificGraphicsPath = [NSString stringWithFormat:@"%@/%@/Graphics.zip",self.claim.fileID,self.claim.clipCode];
    req.prefix = specificGraphicsPath;
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.labelText = @"Downloading graphics..";
    
    __block NSString *eventName = @"Welcome_VehicleGraphicsReceived_BSSpecific";
    
    [[s3 listObjects:req] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
            [HUD hide:YES];
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            NSArray *listofobjects = listObjectsOutput.contents;
            if (listofobjects == nil || [listofobjects count] != 1 ) {
                NSString *genericGraphicsPath = [NSString stringWithFormat:@"%@/Graphics.zip",self.claim.clipCode];
                req.prefix = genericGraphicsPath;
                [[s3 listObjects:req] continueWithBlock:^id(BFTask *task2) {
                    AWSS3ListObjectsOutput *listObjectsOutput2 = task2.result;
                    NSArray *listofobjects2 = listObjectsOutput2.contents;
                    if([listofobjects2 count] == 1) {
                        eventName = @"Welcome_VehicleGraphicsReceived_BSGeneric";
                        AWSS3Object *summary2 = [listObjectsOutput2.contents objectAtIndex:0];
                        [self downloadingGraphicsFromBucket:bucket forAWSS3Object:summary2];
                    } else {
                        eventName = @"Welcome_VehicleGraphicsReceived_Generic";
                        [self copyAndUnzip];
                    }
                    
                    [self saveMetrics:eventName];
                    
                    return nil;
                }];
            } else {
                AWSS3Object *summary = [listObjectsOutput.contents objectAtIndex:0];
                [self downloadingGraphicsFromBucket:bucket forAWSS3Object:summary];
                [self saveMetrics:eventName];
            }
        }
        return nil;
    }];
}

- (void)copyAndUnzip {
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:AUDAEXPLORE_GTD_BUNDLE withExtension:@"bundle"]];
    NSString *zipPath = [bundle pathForResource:@"Graphics" ofType:@"zip"];
    NSString *destinationPath = [self getDocumentsPath];
    
    if([SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]) {
        [self addSkipBackupAttributeToItemAtURL:[self getCarDirectoryURL]];
        [self addSkipBackupAttributeToItemAtURL:[self getMasksDirectoryURL]];
        
        bGraphicsDownloadComplete = YES;
        
        //if the damage viewer is already downloaded, then dismiss the hud
        if(bDamageDownloadComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [HUD hide:YES];
            });
        } else {
            HUD.mode = MBProgressHUDModeIndeterminate;
            HUD.labelText = @"Downloading damage viewer..";
        }
    }
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
    NSError *error = nil;
    [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    return error == nil;
}

- (void)moveToVehicleSelection {
    AEVehicleInfoViewController *viewController = [[AEVehicleInfoViewController alloc] initWithNibName:@"AEVehicleInfoViewController"];
    viewController.strOwnerNameText = @"Please identify your vehicle";
    viewController.strLetStartText = @"";
    viewController.claim = self.claim;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)moveToDamageViewer {
    if([self.globalInstance damageViewerEnabled]) {
        ANWebGLPlaceHolderViewController *viewController = [[ANWebGLPlaceHolderViewController alloc] initWithNibName:@"ANWebGLPlaceHolderViewController"];
        viewController.claim = self.claim;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        ANPhotoViewController *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANPhotoViewController alloc] initWithNibName:@"ANPhotoViewController4"];
        } else {
            viewController = [[ANPhotoViewController alloc] initWithNibName:@"ANPhotoViewController"];
        }
        viewController.claim = self.claim;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
