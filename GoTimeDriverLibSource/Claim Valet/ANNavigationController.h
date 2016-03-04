//
//  ANNavigationController.h
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/13/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelfServiceEstimateDelegate
- (void) backToHost:(NSDictionary *)resultDictionary;
@end

@interface ANNavigationController : UINavigationController

//delegate
@property (nonatomic, assign) id<SelfServiceEstimateDelegate> selfServiceEstimateDelegate;

@end
