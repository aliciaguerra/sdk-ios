//
//  ANConfirmPhotoViewController.h
//  Claim Valet
//
//  Created by Anthony Doan on 6/27/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANCameraViewController.h"

@interface ANConfirmPhotoViewController : ANClaimViewController
{
    
}

@property (nonatomic, assign) id<ANCameraViewDelegate> delegate;
@property (nonatomic, retain) UIImage *photoImage;
@property (nonatomic, retain) IBOutlet UIImageView *ivPhoto;

- (IBAction)usePhoto:(id)sender;
- (IBAction)retakePhoto:(id)sender;

@end
