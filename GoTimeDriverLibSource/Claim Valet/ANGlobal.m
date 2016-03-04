//
//  ANGlobal.m
//  Self-ServiceEstimateDriver
//
//  Created by Quan Nguyen on 8/10/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANGlobal.h"
#import <sys/utsname.h>
#import <CommonCrypto/CommonCryptor.h>  
#import "ANClaimViewController.h"

static ANGlobal *globalInstance;

@interface ANGlobal () <UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableDictionary *configurations;
@property (nonatomic, strong) ANNavigationController *navigationController;
@property (nonatomic, readwrite) BOOL photoLocationRequired;
@property (nonatomic, assign) BOOL bWebGlSupport;
@property (nonatomic, assign) BOOL bEnableDamageViewer;
@end

@implementation ANGlobal

@synthesize configurations;
@synthesize vehicleYear;
@synthesize vehicleMake;
@synthesize vehicleModel;
@synthesize vehicleStyle;
@synthesize isUsingEdmunds;
@synthesize suppressedVehicles;
@synthesize accessKey;
@synthesize secretKey;
@synthesize s3bucket;
@synthesize ngpPassword;
@synthesize ngpUsername;
@synthesize photoLocations;
@synthesize photoLocationRequired;
@synthesize loopBackAPIHelper;
@synthesize bVideoInstruction;
@synthesize bWebGlSupport;
@synthesize bLMPhotoLocationRequired;
@synthesize errorCode;
@synthesize errorDescription;
@synthesize navigationController;
@synthesize bEnableDamageViewer;

+ (ANGlobal *)getGlobalInstance {
    if(globalInstance == nil) {
        globalInstance = [[ANGlobal alloc] init];
    }
    return globalInstance;
}

- (ANGlobal *)init {
    self = [super init];
    if(self) {
        loopBackAPIHelper = [[ANLoopBackClientHelper alloc] init];
        
        photoLocations = [NSMutableDictionary dictionaryWithDictionary:@{}];
        configurations = [[NSMutableDictionary alloc] init];
        
        //check for webgl support: ios 8 and later & not iphone 4
        NSString *reqSysVer = @"8.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        
        NSString *device = [self deviceModelName];
        if (  ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedDescending) ||
                ( [device hasPrefix:@"iPhone 4"]) ||
                ( [device hasPrefix:@"iPad Mini"]) ||
                ( [device isEqualToString:@"iPad"]) ) {
            bWebGlSupport = NO;
        } else {
            bWebGlSupport = YES;
        }
        
        //default bEnableDamageViewer to YES
        bEnableDamageViewer = YES;
    }
    return self;
}

- (NSString*)deviceModelName {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"iPad Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      @"iPhone7,1":    @"iPhone 6+ (GSM+CDMA)",
      @"iPhone7,2":    @"iPhone 6 (GSM+CDMA)",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini(WiFi)",
      @"iPad2,6":  @"iPad Mini(GSM)",
      @"iPad2,7":  @"iPad Mini(GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}

-(void)setGlobalVariables:(NSArray *) objects {
    for (int i = 0; i < objects.count; i++) {
        id object = [objects objectAtIndex:i];
        NSString *key = object[CONFIG_KEY_NAME];
        NSString *value = object[CONFIG_VALUE_NAME];
        [configurations setValue:value forKey:key];
        
        if ([key isEqualToString:@"Amazon.S3.AccessKey"]) {
            self.accessKey = value;
        } else if ([key isEqualToString:@"Amazon.S3.SecretKey"]) {
            self.secretKey = value;
        } else if ([key isEqualToString:@"Amazon.S3.Bucket.WebGL"]) {
            self.s3bucket = value;
        } else if ([key isEqualToString:@"NGP.Username"]) {
            self.ngpUsername = value;
        } else if ([key isEqualToString:@"NGP.Password"]) {
            self.ngpPassword = value;
        } else if ([key isEqualToString:@"Suppressed.Vehicle.Makes"]){
            self.suppressedVehicles = value;
        } else if ([key isEqualToString:@"PhotoLocation.Required"]) {
            self.photoLocationRequired = ([value caseInsensitiveCompare:@"yes"] == NSOrderedSame);
        } else if ([key isEqualToString:@"EnableDamageViewer_iOS"]) {
            self.bEnableDamageViewer = ([value caseInsensitiveCompare:@"yes"] == NSOrderedSame);
        }
    }
}

- (NSData *)encrypt:(NSData *)inData  withKey:(NSString *)key{
    NSData  *retVal = nil;
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero( keyPtr, sizeof(keyPtr) );// fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [inData length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );
    bzero(buffer, bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt( kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [inData bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted );
    
    if (cryptStatus == kCCSuccess) {
        NSData *encryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
        retVal = encryptedData;
    } else {
        free(buffer);
    }
    return retVal;
}

- (NSData *)decrypt:(NSData *)inData  withKey:(NSString *)key {
    NSData  *retVal = nil;
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero( keyPtr, sizeof( keyPtr ) ); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [inData length];
    
    //add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt( kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL, /* initialization vector (optional) */
                                          [inData bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted );
    
    if( cryptStatus == kCCSuccess ){
        NSData *output = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        retVal = output;
    }
    else{
        free(buffer);
    }
    return retVal;
}

-(BOOL) requirePhotoLocation {
    return (bLMPhotoLocationRequired && photoLocationRequired);
}

- (void) setNavCon:(ANNavigationController *)navCon {
    self.navigationController = navCon;
}

- (ANNavigationController *)getNavCon {
    return  self.navigationController;
}

- (BOOL) damageViewerEnabled {
    return (self.bEnableDamageViewer && self.bWebGlSupport);
}

@end

