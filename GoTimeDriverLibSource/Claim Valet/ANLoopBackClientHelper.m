//
//  ANLoopBackClientHelper.m
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 5/14/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANLoopBackClientHelper.h"

//DEV
//#define MOBILE_BACK_END_ACCESS_TOKEN_URL @"https://mobile-dev.audaexplore.com/oauth/token"
//#define MOBILE_BACK_END_CLIENT_ID @"4fdf493cec1227b4d94f52d7737a1f94"
//#define MOBILE_BACK_END_CLIENT_SECRET @"7e3e2230230ed8587053f9ed8b7d4901d8a69533"
//#define MOBILE_BACK_END_URL @"https://mobile-dev.audaexplore.com/api"

//INT1
#define MOBILE_BACK_END_ACCESS_TOKEN_URL @"https://mobile-int1.audaexplore.com/oauth/token"
#define MOBILE_BACK_END_CLIENT_ID @"7aaf66d2e0d977122a6527d1fcb22556"
#define MOBILE_BACK_END_CLIENT_SECRET @"646520c4675a8d69f8cded72c3edd3c8ff8df4f8"
#define MOBILE_BACK_END_URL @"https://mobile-int1.audaexplore.com/api"

//CAE
//#define MOBILE_BACK_END_ACCESS_TOKEN_URL @"https://mobile-cae.audaexplore.com/oauth/token"
//#define MOBILE_BACK_END_CLIENT_ID @"3212d5fff3161399f3fe64594458cd50"
//#define MOBILE_BACK_END_CLIENT_SECRET @"4a1179bfb84122f334c7d9da45ad968c8d52cd3c"
//#define MOBILE_BACK_END_URL @"https://mobile-cae.audaexplore.com/api"

//PROD
//#define MOBILE_BACK_END_ACCESS_TOKEN_URL @"https://mobile.audaexplore.com/oauth/token"
//#define MOBILE_BACK_END_CLIENT_ID @"3212d5fff3161399f3fe64594458cd50"
//#define MOBILE_BACK_END_CLIENT_SECRET @"4a1179bfb84122f334c7d9da45ad968c8d52cd3c"
//#define MOBILE_BACK_END_URL @"https://mobile.audaexplore.com/api"

#define ACCESS_TOKEN_FORMAT @"Bearer %@"

@implementation ANLoopBackClientHelper

@synthesize accessTokenLB;
@synthesize adapter;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.adapter = [LBRESTAdapter adapterWithURL:[NSURL URLWithString:MOBILE_BACK_END_URL]];
        [self getAccessTokenFromServer];
    }
    return self;
}

-(BOOL)substring:(NSString *)substr existsInString:(NSString *)str {
    if(!([str rangeOfString:substr options:NSCaseInsensitiveSearch].length==0)) {
        return YES;
    }
    
    return NO;
}

-(BOOL)accessTokenIsExpired:(NSError*)error
{
    if (self.accessTokenLB == nil
        || [self substring:@"Access token is expired" existsInString:error.localizedRecoverySuggestion]
        || [self substring:@"Unauthorized" existsInString:error.localizedRecoverySuggestion]) {
        return YES;
    }
    
    return NO;
}
-(void)callMobileBackEnd:(NSString *)dataModel
              methodName:(NSString *)methodName
              parameters:(NSDictionary *)parameters
              retryTimes:(int) retryTimes
                 success:(MBEApiCallSuccessBlock)success
                 failure:(MBEFailureBlock)failure
{
    double startTimestamp = [[NSDate new] timeIntervalSince1970];
    
    void (^serviceCallErrorHandler)(NSError *) = ^(NSError *error){
        if([self accessTokenIsExpired:error]) {
            if (retryTimes <= 3) {
                [self getAccessTokenFromServer];
                [self callMobileBackEnd:dataModel methodName:methodName parameters:parameters retryTimes: retryTimes+1 success:success failure:failure];
            } else {
                failure(error);
            }
        } else {
            failure(error);
        }
    };
    
    LBModelRepository *repository = [[self adapter] repositoryWithModelName:dataModel];
    if ([methodName isEqualToString:@"findById"]) {
        [repository findById:[parameters valueForKey:@"id"] success:^(LBModel *model) {
            [self logTimeDifference:startTimestamp methodName:methodName dataModal:dataModel];
            success(model);
        } failure:serviceCallErrorHandler];
    } else if([methodName isEqualToString:@"saveWithSuccess"]) {
        LBModel *data = [repository modelWithDictionary:parameters];
        [data saveWithSuccess:^{
            [self logTimeDifference:startTimestamp methodName:methodName dataModal:dataModel];
            success(data);
        } failure:serviceCallErrorHandler];
    } else {
        [repository invokeStaticMethod:methodName parameters:parameters success:^(id value) {
            [self logTimeDifference:startTimestamp methodName:methodName dataModal:dataModel];
            success(value);
        } failure:serviceCallErrorHandler];
    }
}

-(void)logTimeDifference:(double)startTimestamp
              methodName:(NSString*)methodName
               dataModal:(NSString*)dataModal
{
    double dif = [[NSDate date] timeIntervalSince1970] - startTimestamp;
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setPositiveFormat:@"0.##"];
    NSLog(@"It took %@s for method of %@ and data modal of %@",[fmt stringFromNumber:[NSNumber numberWithDouble:dif]],methodName,dataModal);
}

-(void)callMobileBackEnd:(NSString *)dataModel
              methodName:(NSString *)methodName
              parameters:(NSDictionary *)parameters
              success:(MBEApiCallSuccessBlock)success
              failure:(MBEFailureBlock)failure
{

    [self callMobileBackEnd:dataModel methodName:methodName parameters:parameters retryTimes:0 success:success failure:failure];
}
-(void) getAccessTokenFromServer
{
    NSString *jsonRequest = [NSString stringWithFormat:@"{\"client_id\":\"%@\",\"client_secret\":\"%@\",\"grant_type\":\"client_credentials\",\"scope\":\"post\"}",MOBILE_BACK_END_CLIENT_ID,MOBILE_BACK_END_CLIENT_SECRET];
    
    NSURL *url = [NSURL URLWithString:MOBILE_BACK_END_ACCESS_TOKEN_URL];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSURLResponse *response = [[NSURLResponse alloc] init];
    NSError *resError = [[NSError alloc] init];
    NSData* result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&resError];
    if (result == nil) {
       [ANUtils errorHandle:resError withLogMessage:@"Didn't receive access token from server."];
    } else {
        NSError *error = nil;
        id accessToken = [NSJSONSerialization JSONObjectWithData:result options:0 error:&error];
        if (error) {
            NSLog(@"Error in JSON serialization: %@", [error userInfo]);
        } else {
            NSDictionary *object = accessToken;
            NSLog(@"Access Token is %@", [object valueForKey:@"access_token"]);
            self.accessTokenLB =[object valueForKey:@"access_token"];
            [self.adapter setAccessToken:[NSString stringWithFormat:ACCESS_TOKEN_FORMAT, self.accessTokenLB]];
        }
    }
}

- (NSData*)callMobileBackEnd: (NSString *)dataModel
                                methodName:(NSString *)methodName
                                parameter:(NSString *)parameter
    {
        
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",MOBILE_BACK_END_URL,dataModel,methodName]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSData *requestData = [NSData dataWithBytes:[parameter UTF8String] length:[parameter length]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:ACCESS_TOKEN_FORMAT, self.accessTokenLB] forHTTPHeaderField:@"Authorization"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody: requestData];
    NSURLResponse *response = [[NSURLResponse alloc] init];
    NSError *resError = [[NSError alloc] init];
    NSData* result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&resError];
    if (result == nil) {
        if([self accessTokenIsExpired:resError]) {
            return [self callMobileBackEnd:dataModel methodName:methodName parameter:parameter];
        } else {
           [ANUtils errorHandle:resError withLogMessage:@"Didn't receive access token from server."];
            return result;
        }
    }
    return result;
}

@end
