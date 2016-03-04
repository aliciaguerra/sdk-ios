//
//  ANWebServiceHelper.m
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 5/6/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANWebServiceHelper.h"

@implementation ANWebServiceHelper
+(NSString*) getVINDecodeRequestMessage: (NSString*) vin
{
    NSString *format = VIN_Decode_Request_Message;
    NSString *requestMessage = [NSString stringWithFormat:format,vin];
    NSLog(@"Request Message is %@",requestMessage);
    return requestMessage;
}
+(NSString*) getMakesRequestMessage: (NSString*) year
{
    NSString *format = GetMakes_Request_Message;
    NSString *requestMessage = [NSString stringWithFormat:format, year];
    NSLog(@"Request Message is %@",requestMessage);
    return requestMessage;
}
+(NSString*) getModelsRequestMessage : (NSString*) year : (NSString*) make
{
    NSString *format = GetModels_Request_Message;
    NSString *requestMessage = [NSString stringWithFormat:format, year,make];
    NSLog(@"Request Message is %@",requestMessage);
    return requestMessage;
}
+(NSString*) getStylesRequestMessage : (NSString*) year : (NSString*) make : (NSString*)model
{
    NSString *format = GetStyles_Request_Message;
    NSString *requestMessage = [NSString stringWithFormat:format,year,make,model];
    NSLog(@"Request Message is %@",requestMessage);
    return requestMessage;
}
+(NSMutableURLRequest*) getMessageRequest : (NSString *) message : (NSString*) username :(NSString*) password
{
    NSURL *sRequestURL = [NSURL URLWithString:kAEInternetResourceAdaptor_WebServiceURL_Production];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:sRequestURL];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[message length]];
    
    [theRequest addValue: @"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [theRequest addValue: username forHTTPHeaderField:@"Username"];
    [theRequest addValue: password forHTTPHeaderField:@"Password"];
    [theRequest addValue: @"application/json" forHTTPHeaderField:@"Accept"];
    [theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody: [message dataUsingEncoding:NSUTF8StringEncoding]];
    return theRequest;
}
+(id) getJsonMessage : (NSMutableData *) receivedData
{
    NSString *responseStr = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSLog(@"The response message from service is %@." , responseStr);
    if (responseStr) {
        NSRange rangeOfXMLResponse = [responseStr rangeOfString:@"<Response><![CDATA["];
        if (rangeOfXMLResponse.location != NSNotFound)
        {
            responseStr = [responseStr componentsSeparatedByString:@"<Response><![CDATA["].lastObject;
            responseStr = [[responseStr componentsSeparatedByString:@"]]></Response>"] objectAtIndex:0];
            NSData *jsonData = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            id result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (error)
            {
                NSLog(@"Error in JSON serialization: %@", [error userInfo]);
                return nil;
                
            } else {
                return result;
            }
        }
    }
    return nil;
}
@end
