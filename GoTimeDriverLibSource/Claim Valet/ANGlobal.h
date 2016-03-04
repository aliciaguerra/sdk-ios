
#import <Foundation/Foundation.h>
#import "ANLoopBackClientHelper.h"
#import "ANNavigationController.h"

#define CONFIGURATION_MODEL_NAME @"Configurations"
#define INSTALLATIONS_MODEL_NAME @"Installations"
#define USERACTIONUTILITIES_DATA_MODEL_NAME @"UserActionUtilities"
#define CLAIM_DATA_MODEL_NAME @"Claims"
#define SURVEYDATA_MODEL_NAME @"SurveyDatas"
#define ATTACHMENT_MODEL_NAME @"Attachments"
#define PUSH_DATA_MODEL_NAME @"Push"
#define CONFIG_KEY_NAME @"configKey"
#define CONFIG_VALUE_NAME @"configValue"
#define ORGID_KEY_NAME @"orgId"
#define ORGID_VALUE @"477"
#define AUDAEXPLORE_GTD_BUNDLE @"AudaExploreGTDLibResources"

#define SELF_SERVICE_ESTIMATE_SUCCESS 0
#define SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL 1
#define SELF_SERVICE_ESTIMATE_ERROR_CANNOT_CONNECT_TO_SERVER 2
#define SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST 3
#define SELF_SERVICE_ESTIMATE_ERROR_ALREADY_COMPLETED 4

#define DESCRIPTION_SELF_SERVICE_ESTIMATE_SUCCESS @"Self-Service Estimate completed successfully."
#define DESCRIPTION_SELF_SERVICE_ESTIMATE_SUCCESS_USER_CANCEL @"User cancels Self-Service Estimate process."
#define DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CANNOT_CONNECT_TO_SERVER @"We are currently unable to connect to the server. Please ensure you have internet access and try again. If the problem persists please contact customer support."
#define DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_CLAIM_NOT_EXIST @"We are unable to find your claim. Please try again later. If the problem persists please contact customer support."
#define DESCRIPTION_SELF_SERVICE_ESTIMATE_ERROR_ALREADY_COMPLETED @"Your damage information has been submitted."


@interface ANGlobal : NSObject
// Vehicle Data
@property (nonatomic, strong) NSString *vehicleYear;
@property (nonatomic, strong) NSString *vehicleMake;
@property (nonatomic, strong) NSString *vehicleModel;
@property (nonatomic, strong) NSString *vehicleStyle;
@property (nonatomic, readwrite) BOOL isUsingEdmunds;
@property (nonatomic, retain) NSString *suppressedVehicles;

// Amazon
@property (nonatomic, retain) NSString *accessKey;
@property (nonatomic, retain) NSString *secretKey;
@property (nonatomic, retain) NSString *s3bucket;


// Autosource Login
@property (nonatomic, retain) NSString *ngpUsername;
@property (nonatomic, retain) NSString *ngpPassword;

// Photo Location
@property (nonatomic, retain) NSMutableDictionary *photoLocations;

//loopback
@property (nonatomic,strong) ANLoopBackClientHelper *loopBackAPIHelper;

//video vs. text
@property (nonatomic, assign) BOOL bVideoInstruction;

//lat/long toggle from LM
@property (nonatomic, assign) BOOL bLMPhotoLocationRequired;

+ (ANGlobal *)getGlobalInstance;
- (NSString*)deviceModelName;
- (NSData *)encrypt:(NSData *)inData withKey:(NSString *)key;
- (NSData *)decrypt:(NSData *)inData withKey:(NSString *)key;
- (BOOL) requirePhotoLocation;
- (void) setNavCon:(ANNavigationController *)navCon;
- (ANNavigationController *)getNavCon;
-(void)setGlobalVariables:(NSArray *) objects;
- (BOOL) damageViewerEnabled;

//error handling
@property (nonatomic, assign) int errorCode;
@property (nonatomic, assign) NSString *errorDescription;

@end
