//
//  GTDSEdmundsAEBodyStyle.h
//  GTDSMaaco
//
//  Created by Quan Nguyen on 5/6/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTDSEdmundsAEBodyStyle : NSObject

- (id) initClipCodeMappingsWithFile:(NSString *)filePath;
- (NSString*) getAEBodyStyleForEdmundsStyle:(NSString*)edmundsBodyStyle;
@property (strong, nonatomic) NSMutableDictionary *bodyStyleMapping;

@end
