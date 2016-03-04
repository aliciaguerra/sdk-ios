//
//  ANWebServiceHelper.h
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 5/6/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kAEInternetResourceAdaptor_WebServiceURL_Production @"https://vis.audaexplore.com/GadgetProxy/GadgetProxy.aspx"
#define VIN_Decode_Request_Message @"<Request Method=\"igetdecode\"><![CDATA[{\"GadgetID\":\"3170CE00-900B-D2DF-DD36-C87EFF7E328E\",\"VIN\":\"%@\",\"PostalCode\":\"97222\"}]]></Request>";
#define GetMakes_Request_Message @"<Request Method=\"igetmakes\"><![CDATA[{\"GadgetID\":\"3170CE00-900B-D2DF-DD36-C87EFF7E328E\",\"Year\":\"%@\",\"PostalCode\":\"97222\"}]]></Request>"
#define GetModels_Request_Message @"<Request Method=\"igetmodels\"><![CDATA[{\"GadgetID\":\"3170CE00-900B-D2DF-DD36-C87EFF7E328E\",\"Year\":\"%@\",\"Make\":\"%@\",\"PostalCode\":\"97222\"}]]></Request>"
#define GetStyles_Request_Message @"<Request Method=\"igetstyles\"><![CDATA[{\"GadgetID\":\"3170CE00-900B-D2DF-DD36-C87EFF7E328E\",\"Year\":\"%@\",\"Make\":\"%@\",\"Model\":\"%@\",\"PostalCode\":\"97222\"}]]></Request>"

@interface ANWebServiceHelper : NSObject
+(NSString*) getVINDecodeRequestMessage : (NSString*) vin;
+(NSString*) getMakesRequestMessage : (NSString*) year;
+(NSString*) getModelsRequestMessage : (NSString*) year : (NSString*) make;
+(NSString*) getStylesRequestMessage : (NSString*) year : (NSString*) make : (NSString*)model;
+(NSMutableURLRequest*) getMessageRequest : (NSString *) message : (NSString*) username :(NSString*) password;
+(id) getJsonMessage : (NSMutableData *) receivedData;

@end
