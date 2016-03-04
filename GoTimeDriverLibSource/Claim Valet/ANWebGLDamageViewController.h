//
//  ANWebGLDamageViewController.h
//  Claim Valet
//
//  Created by Quan Nguyen on 6/25/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ANClaimViewController.h"

@protocol ANWebGLDamageViewControllerDelegate <NSObject>
- (void) onNextClicked;
- (void) onBackClicked;
- (void) onCancelClicked;
- (void) setDamageViewerPresented:(BOOL) value;
@end

@interface ANWebGLDamageViewController : ANClaimViewController <UIWebViewDelegate>
@property (strong, nonatomic) UIWebView *wvWebGlViewer;
@property (nonatomic, assign) id<ANWebGLDamageViewControllerDelegate> delegate;
@end
