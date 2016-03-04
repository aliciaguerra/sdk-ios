//
//  ANVehicleStyleMappingReader.m
//  Claim Valet
//
//  Created by Audatex on 8/17/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import "ANVehicleStyleMappingReader.h"
#import "ANGlobal.h"

@implementation ANVehicleStyleMappingReader

@synthesize fileIdStrings;
@synthesize clipCodeMappingStrings;

int styleIndex = 1;
int clipCodeIndex = 2;
int clipCodeForBodyStyleDescIndex = 0;
int bodyStyleDescriptionIndex = 1;

-(NSMutableArray*) fileIdStrings
{
    if(!fileIdStrings) fileIdStrings = [[NSMutableArray alloc] init];
    return fileIdStrings;
}

- (NSMutableArray *) clipCodeMappingStrings
{
    if (!clipCodeMappingStrings) {
        clipCodeMappingStrings = [[NSMutableArray alloc] init];
    }
    
    return clipCodeMappingStrings;
}

- (id) initWithFile: (NSString *) filePath forFileId: (NSString *) fileId{
    self = [super init];
    if(self) {
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:AUDAEXPLORE_GTD_BUNDLE withExtension:@"bundle"]];
        NSString* fileRoot = [bundle pathForResource:filePath ofType:@"txt"];
        NSString * inStr = [NSString stringWithContentsOfFile:fileRoot encoding:NSASCIIStringEncoding error:NULL];
        NSArray * strArray = [inStr componentsSeparatedByString:@"\r\n"];
        for (NSString * strLine in strArray) {
            if([strLine hasPrefix:fileId]){
                [self.fileIdStrings addObject:strLine];
            }
        }
    }
    return self;
}

- (id) initClipCodeMappingsWithFile:(NSString *)filePath
{
    self = [super init];
    if (self) {
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:AUDAEXPLORE_GTD_BUNDLE withExtension:@"bundle"]];
        NSString* fileRoot = [bundle pathForResource:filePath ofType:@"txt"];
        NSString * inStr = [NSString stringWithContentsOfFile:fileRoot encoding:NSASCIIStringEncoding error:NULL];
        NSArray * strArray = [inStr componentsSeparatedByString:@"\r\n"];
        for (NSString * strLine in strArray) {
            [self.clipCodeMappingStrings addObject:strLine];
        }
    }
    return self;
}

- (NSString *) getClipCodeForStyle: (NSString *) style{
    NSString* value = nil;
    for (NSString * strLine in fileIdStrings) {
        NSArray * strArray = [strLine componentsSeparatedByString:@"\t"];
        if(strArray){
            NSString* styleForFileId = (NSString *)[strArray objectAtIndex:styleIndex];
            if([styleForFileId isEqualToString:style]){
                value = (NSString *)[strArray objectAtIndex:clipCodeIndex];
                break;
            }
        }
    }
    return value;
}

- (NSString *) getBodyStyleDescriptionForClipCode:(NSString *) clipCodeStr
{
    NSString* value = nil;
    for (NSString * strLine in clipCodeMappingStrings) {
        NSArray * strArray = [strLine componentsSeparatedByString:@"\t"];
        if(strArray) {
            NSString* clipCodeForFileId = (NSString *)[strArray objectAtIndex:clipCodeForBodyStyleDescIndex];
            if ([clipCodeForFileId isEqualToString:clipCodeStr]) {
                value = (NSString *)[strArray objectAtIndex:bodyStyleDescriptionIndex];
                break;
            }
        }
    }
    return value;
}
@end
