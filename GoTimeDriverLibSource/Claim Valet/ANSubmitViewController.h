//
//  ANSubmitViewController.h
//  Claim Valet
//
//  Created by james.xie@AudaExplore.com on 8/5/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaimViewController.h"
#import "MBProgressHUD.h"

#define appDelegate ((ANAppDelegate *)[[UIApplication sharedApplication] delegate])

@interface ANSubmitViewController : ANClaimViewController<MBProgressHUDDelegate,UITextViewDelegate>
{
    
}
@property (weak, nonatomic) IBOutlet UITextView *addNoteTextView;

@end
