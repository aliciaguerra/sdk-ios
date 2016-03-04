//
//  GTDSVINPortraitViewController.m
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/13/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSVINPortraitViewController.h"

@interface GTDSVINPortraitViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *ivWhereIsMyVin;

@end

@implementation GTDSVINPortraitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
