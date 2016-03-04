//
//  ANUtils.h
//  Claim Valet
//
//  Created by Anthony Doan on 7/1/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CAAnimation.h>
#import <UIKit/UIColor.h>

@interface ANUtils : NSObject
+ (CATransition*)getTransitionFromRight;
+ (CATransition*)getTransitionFromLeft;
+ (CATransition*) getTransitionFromBottom;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (NSString*)formatCurrency:(NSString *)value;
+ (NSString*)getBodyStyleFromServerForFileID:(NSString*)fileID andStyleModel:(NSString*)styleModel;
+ (void)errorHandle:(NSError*)error withLogMessage:(NSString*)logInfo;

@end
