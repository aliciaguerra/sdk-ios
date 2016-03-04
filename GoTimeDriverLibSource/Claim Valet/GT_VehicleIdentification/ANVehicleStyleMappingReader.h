//
//  ANVehicleStyleMappingReader.h
//  Claim Valet
//
//  Created by Audatex on 8/17/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANVehicleStyleMappingReader : NSObject

- (id) initWithFile: (NSString *) filePath forFileId: (NSString *) fileId;
- (NSString *) getClipCodeForStyle: (NSString *) style;

- (id) initClipCodeMappingsWithFile:(NSString *)filePath;
- (NSString *) getBodyStyleDescriptionForClipCode:(NSString *) clipCodeStr;

@property (strong, nonatomic) NSMutableArray *fileIdStrings;
@property (strong, nonatomic) NSMutableArray *clipCodeMappingStrings;
@end
