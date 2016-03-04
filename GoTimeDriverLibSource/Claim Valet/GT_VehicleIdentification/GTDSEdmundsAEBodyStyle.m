//
//  GTDSEdmundsAEBodyStyle.m
//  GTDSMaaco
//
//  Created by Quan Nguyen on 5/6/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSEdmundsAEBodyStyle.h"

@implementation GTDSEdmundsAEBodyStyle

@synthesize bodyStyleMapping;

- (id) initClipCodeMappingsWithFile:(NSString *)filePath {
    self = [super init];
    if(self) {
        
        bodyStyleMapping = [[NSMutableDictionary alloc] init];
        
        NSString* fileRoot = [[NSBundle mainBundle] pathForResource:filePath ofType:@"txt"];
        NSString * inStr = [NSString stringWithContentsOfFile:fileRoot encoding:NSASCIIStringEncoding error:NULL];
        NSArray * strArray = [inStr componentsSeparatedByString:@"\r"];
        for (NSString * strLine in strArray)
        {
            NSArray * strArray = [strLine componentsSeparatedByString:@"\t"];
            NSString *key = [strArray objectAtIndex:0];
            NSString *value = [strArray objectAtIndex:1];

            [bodyStyleMapping setValue:value forKey:key];
        }
    }
    return self;
}


- (NSString*) getAEBodyStyleForEdmundsStyle:(NSString*)edmundsBodyStyle {
    return [bodyStyleMapping valueForKey:edmundsBodyStyle];
}


@end
