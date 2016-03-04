//
//  ANClaim.h
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/9/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <LoopBack/LoopBack.h>


typedef enum{
    leftFront = 101,
    leftRear = 102,
    rightFront = 103,
    rightRear = 104,
    vin = 105,
    odometer = 106,
    damageLeft = 107,
    damageCenter = 108,
    damageRight = 109,
    dvLB = 110,
    dvLBheatmap = 111,
    dvLT = 112,
    dvLTheatmap = 113,
    dvRB = 114,
    dvRBheatmap = 115,
    dvRT = 116,
    dvRTheatmap = 117,
    additionalnumberone= 118,
    additionalnumbertwo = 119,
    additionalnumberthree = 120,
    additionalnumberfour = 121,
    additionalnumberfive = 122,
    additionalnumbersix = 123
}ANPhotoAngle;

typedef enum {
    ANCustomerStatusNew = 0,
    ANCustomerStatusStarted = 1,
    ANCustomerStatusDamage = 2,
    ANCustomerStatusPhotos = 3,
    ANCustomerStatusReview = 4,
    ANCustomerStatusSubmitted = 5,
    ANCustomerStatusEstimateReady = 6,
    ANCustomerStatusPaymentEFT = 7,
    ANCustomerStatusPaymentCheck = 8,
    ANCustomerStatusWithdraw = 9
}ANCustomerStatus;

@interface ANClaim : NSObject

@property ANCustomerStatus customerStatus;
@property (strong,nonatomic) NSString *ownerName;
@property (strong,nonatomic) NSString *yearMakeModel;
@property (strong,nonatomic) NSString *fileID;
@property (strong,nonatomic) NSString *styleID;
@property (strong,nonatomic) NSString *clipCode;

@property (strong, nonatomic) NSString *estimateDeductible;
@property (strong, nonatomic) NSString *estimateNetTotal;
@property (strong, nonatomic) NSNumber *firstOrThirdPartyClaim;

@property (strong, nonatomic) NSString *claimNumber;
@property (strong, nonatomic) NSString *adjustorPhone;
@property (strong, nonatomic) NSString *adjustorEmail;
@property (strong, nonatomic) NSString *adjustorFirstName;
@property (strong, nonatomic) NSString *adjustorLastName;

@property (strong, nonatomic) NSMutableDictionary *lbObject;


-(id) initWithNSDictionary:(NSDictionary*) dictionary;

-(NSMutableDictionary*) getlbObjectForClaim;
@end
