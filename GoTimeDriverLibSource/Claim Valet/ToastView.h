//
//  ToastView.h
//  Claim Valet
//
//  Created by Anthony Doan on 6/26/14.
//  Copyright (c) 2014 Audaexplore, a Solera company. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToastView : UIView

@property (strong, nonatomic) UILabel *textLabel;
+ (void)showToastInParentView: (UIView *)parentView withText:(NSString *)text withDuaration:(float)duration;

@end
