//
//  ANUtils.m
//  Claim Valet
//
//  Created by Anthony Doan on 7/1/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import "ANUtils.h"
#import <LoopBack/LoopBack.h>
#import "ANGlobal.h"

@implementation ANUtils
+ (CATransition*)getTransitionFromRight {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    return transition;
}

+ (CATransition*)getTransitionFromLeft {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.2;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    return transition;
}

+ (CATransition*) getTransitionFromBottom {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionFromBottom;
    transition.subtype = kCATransitionFromBottom;
    return transition;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSString*)formatCurrency:(NSString *)value {
    NSNumberFormatter *currencyStyle = [[NSNumberFormatter alloc] init];
    [currencyStyle setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [currencyStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSNumber *amount = [NSNumber numberWithDouble:[value doubleValue]];
    NSString* formatted = [currencyStyle stringFromNumber:amount];
    
    return formatted;
}

+ (NSString*)getBodyStyleFromServerForFileID:(NSString*)fileID andStyleModel:(NSString*)styleModel {
    NSMutableString *strBodyStyleCode = [[NSMutableString alloc] init];
    NSString *jsonRequest = [NSString stringWithFormat:@"{\"styleModel\":\"%@\",\"vehicleId\":\"%@\"}",styleModel,fileID];
    
    ANGlobal *globalInstance = [ANGlobal getGlobalInstance];
    NSData* result = [[globalInstance loopBackAPIHelper] callMobileBackEnd:@"BodyStyles" methodName:@"findbodystyle" parameter:jsonRequest];
    if (result != nil) {
        NSError *error = nil;
        id bodyStyles = [NSJSONSerialization JSONObjectWithData:result options:0 error:&error];
        if (error) {
            NSLog(@"Error in JSON serialization: %@", [error userInfo]);
        } else if(bodyStyles) {
            if (bodyStyles[@"bodyStyleCode"]) {
                NSLog(@"Vehicle's body style code is %@", bodyStyles[@"bodyStyleCode"]);
                [strBodyStyleCode appendString:bodyStyles[@"bodyStyleCode"]];
            } else if (bodyStyles[@"error"]) {
                NSLog(@"Error for getting Body Style for fileID of %@ and style model of %@: %@", fileID,styleModel,
                    bodyStyles[@"error"]);
            }
        }
    }
    return strBodyStyleCode;
}

+(void)errorHandle:(NSError *)error withLogMessage:(NSString *)logInfo
{
    NSLog(@"%@. %@. %@. %@",logInfo, [error localizedDescription],[error localizedFailureReason],[error localizedRecoverySuggestion]);
}
@end
