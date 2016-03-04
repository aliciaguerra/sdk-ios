//
//  ANCameraPreviewView.m
//  Claim Valet
//
//  Created by Tung Hoang on 3/19/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import "ANCameraPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation ANCameraPreviewView

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
