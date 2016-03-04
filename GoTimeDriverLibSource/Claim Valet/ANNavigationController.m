//
//  ANNavigationController.m
//  Claim Valet
//
//  Created by Sarvesh Chinnappa on 8/13/13.
//  Copyright (c) 2013 Audaexplore, a Solera company. All rights reserved.
//

#import "ANNavigationController.h"

@interface ANNavigationController ()
@end

@implementation ANNavigationController
@synthesize selfServiceEstimateDelegate;

- (BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject]  preferredInterfaceOrientationForPresentation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

@end
