//
//  ViewController.m
//  HostApplication
//
//  Created by Quan Nguyen on 11/17/15.
//  Copyright © 2015 AudaExplore, a Solera Company. All rights reserved.
//

#import "ViewController.h"
#import <AudaExploreGTDLib/ANNavigationController.h>
#import <AudaExploreGTDLib/ANLoginViewController.h>

@interface ViewController () <SelfServiceEstimateDelegate>

@end

@implementation ViewController

- (IBAction)launchSelfServiceEstimateClicked:(UIButton *)sender {
    NSMutableDictionary *claimInfo = [[NSMutableDictionary alloc] init];
    [claimInfo setObject:@"18-575L-89389" forKey:@"claimNumber"];
    [claimInfo setObject:@"yes" forKey:@"videoInstruction"];
    [claimInfo setObject:@"yes" forKey:@"photoLocationRequired"];
    
    NSError *error;
    NSData *claimInfoJson = [NSJSONSerialization dataWithJSONObject:claimInfo
                                                            options:NSJSONWritingPrettyPrinted
                                                              error:&error];
    
    ANLoginViewController * loginVC = [[ANLoginViewController alloc] initWithClaimJson:claimInfoJson];
    ANNavigationController *navCon = [[ANNavigationController alloc] initWithRootViewController:loginVC];
    navCon.selfServiceEstimateDelegate = self;
    [self presentViewController:navCon animated:YES completion:nil];
}

- (void) backToHost:(NSDictionary *)resultDictionary; {
    long errorCode = [[resultDictionary valueForKey:@"errorCode"] integerValue];
    long customerStatus = [[resultDictionary valueForKey:@"customerStatusCode"]  integerValue];
    NSString *errorMessage = [resultDictionary valueForKey:@"errorMsg"];
    
    NSLog(@"Result: code %ld - customer status %ld - message: %@", errorCode, customerStatus, errorMessage);
}

@end
