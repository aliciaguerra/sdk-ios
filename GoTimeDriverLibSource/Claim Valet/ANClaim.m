//
//  ANClaim.m
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/9/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import "ANClaim.h"
//#import "ANVehicleStyleMappingReader.h"

@implementation ANClaim

@synthesize ownerName;
@synthesize yearMakeModel;
@synthesize estimateDeductible;
@synthesize estimateNetTotal;
@synthesize lbObject;

-(id) initWithNSDictionary:(NSDictionary*) dictionary
{
    self = [super init];
    if (self) {
        self.lbObject = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        self.customerStatus = [[dictionary objectForKey:@"customerStatus"] intValue];
        self.ownerName = dictionary[@"vehicleOwnerFirstName"];
        
        NSString *vehicleYear = ((dictionary[@"estimateVehicleYear"] != nil && dictionary[@"estimateVehicleYear"] !=(id)[NSNull null]) ? dictionary[@"estimateVehicleYear"] : @"");
        NSString *vehicleMake = ((dictionary[@"estimateVehicleMake"] != nil && dictionary[@"estimateVehicleMake"] !=(id)[NSNull null]) ? dictionary[@"estimateVehicleMake"] : @"");
        NSString *vehicleModel = ((dictionary[@"estimateVehicleModel"] != nil && dictionary[@"estimateVehicleModel"] !=(id)[NSNull null])? dictionary[@"estimateVehicleModel"] :@"");
        
        if (vehicleYear.length > 0 && vehicleMake.length > 0 && vehicleModel.length > 0) {
            self.yearMakeModel = [NSString stringWithFormat:@"%@ %@ %@", vehicleYear, vehicleMake, vehicleModel];
        }
        
        self.fileID = dictionary[@"vehicleFileId"];
        self.styleID = dictionary[@"vehicleStyleCode"];
        
        self.estimateDeductible = dictionary[@"deductible"];
        self.estimateNetTotal = dictionary[@"estimateNetTotal"];
        
        self.firstOrThirdPartyClaim = [NSNumber numberWithInt:1];
        
        self.claimNumber = dictionary[@"claimNumber"];
        
        //TODO claims Table is Missing all following fields.
        self.adjustorPhone = dictionary[@"staffAppraiserCellPhone"];
        self.adjustorEmail = dictionary[@"staffAppraiserEmailAddress"];
        self.adjustorFirstName = dictionary[@"staffAppraiserFirstName"];
        self.adjustorLastName = dictionary[@"staffAppraiserLastName"];
    }
    return self;
}

-(NSMutableDictionary*) getlbObjectForClaim
{
    [lbObject setObject:[NSNumber numberWithInt:self.customerStatus] forKey:@"customerStatus"];
    return lbObject;
}

@end
