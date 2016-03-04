//
//  ANLoopBackClientHelper.h
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 5/14/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LoopBack/LoopBack.h>
#import "ANUtils.h"

@interface ANLoopBackClientHelper : NSObject
//loopback
@property (nonatomic, strong) LBRESTAdapter *adapter;
@property (nonatomic, strong) NSString *accessTokenLB;


typedef void (^MBEApiCallSuccessBlock)(id value);

typedef void (^MBEFailureBlock)(NSError *error);


-(void) callMobileBackEnd:(NSString*)dataModel
               methodName:(NSString*)methodName
               parameters:(NSDictionary*)parameters
               success:(MBEApiCallSuccessBlock)success
               failure:(MBEFailureBlock)failure;

- (NSData*)callMobileBackEnd: (NSString *)dataModel
                  methodName:(NSString *)methodName
                   parameter:(NSString *)parameter;
@end
