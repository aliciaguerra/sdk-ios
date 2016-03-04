//
//  AEViewController.m
//  Gadget
//
//  Created by Silas Marshall on 7/2/13.
//  Copyright (c) 2013 AudaExplore. All rights reserved.
//

#import "AEViewController.h"
#import "ANClaimViewController.h"

@implementation AEViewController
	{
	UIView	*_viewForStandby;
	}

#pragma mark - standby

- (void)hideStandbyView
	{
	[UIView animateWithDuration:0.5
		animations:
			^{
			_viewForStandby.alpha = 0.0;
			}
		completion:^(BOOL finished)
			{
			[_viewForStandby removeFromSuperview];
			}];
	}

- (void)showStandbyView
	{
	[self showStandbyView:NO];
	}

- (void)showStandbyView:(BOOL)coverEntireWindow
	{
	if (!_viewForStandby)
		{
		if (coverEntireWindow)
			{
			_viewForStandby = [[UIView alloc] initWithFrame:self.view.window.frame];
			}
		else
			{
			_viewForStandby = [[UIView alloc] initWithFrame:self.view.frame];
			}
		_viewForStandby.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[_viewForStandby addSubview:activityIndicatorView];
		activityIndicatorView.center = _viewForStandby.center;
		[activityIndicatorView startAnimating];
		}

	_viewForStandby.alpha = 0.0;
	if (coverEntireWindow)
		{
		[self.view.window insertSubview:_viewForStandby atIndex:100];
		}
	else
		{
		[self.view insertSubview:_viewForStandby atIndex:100];
		}

	[UIView animateWithDuration:0.5
		animations:
			^{
			_viewForStandby.alpha = 1.0;
			}];
	}

#pragma mark - helpers

- (void)hideKeyboard
	{
	[self.view endEditing:YES];
	}

- (void)setupBackground
	{
	_imageViewBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    if (!self.navigationController.navigationBarHidden)
		{
		_imageViewBackground.frame = CGRectOffset(_imageViewBackground.frame, 0, -self.navigationController.navigationBar.frame.size.height);
		}
	_imageViewBackground.contentMode = UIViewContentModeTop;
	[self.view insertSubview:_imageViewBackground atIndex:0];
	}

- (void)viewDidLoad
	{
	[super viewDidLoad];
	[self setupBackground];
	}

@end
