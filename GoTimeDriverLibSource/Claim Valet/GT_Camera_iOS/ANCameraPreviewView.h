//
//  ANCameraPreviewView.h
//  Claim Valet
//
//  Created by Tung Hoang on 3/19/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface ANCameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
