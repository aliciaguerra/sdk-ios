//
//  GTDSSelectYearViewController.m
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/11/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSSelectYearViewController.h"
#import "GTDSSelectMakeViewController.h"

@interface GTDSSelectYearViewController ()

@end

@implementation GTDSSelectYearViewController

@synthesize tvYears;

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
    [self saveMetrics:@"VIDSelectYear_PageLoaded"];
    // Do any additional setup after loading the view from its nib.
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger year = [components year];
    
    // initial value is next year
    ++year;
    
    yearsArr = [[NSMutableArray alloc] init];
    
    while (year >= 1960)
    {
        [yearsArr addObject:[NSString stringWithFormat:@"%ld", (long)year]];
        --year;
    }
    
    [tvYears reloadData];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reduce the size of the table view for iPhone 4.
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        CGRect tableFrame = [self.tvYears frame];
        tableFrame.size.height -= 88;
        [self.tvYears setFrame:tableFrame];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [yearsArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil )
    {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [yearsArr objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveMetrics:@"VIDSelectYear_Selected"];
    
    if (![self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
    self.globalInstance.vehicleYear = [yearsArr objectAtIndex:indexPath.row];
    
    GTDSSelectMakeViewController *viewController = [[GTDSSelectMakeViewController alloc] initWithNibName:@"GTDSSelectMakeViewController"];
    viewController.claim = self.claim;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"PLEASE SELECT A YEAR";
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (IBAction)backClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.isMovingFromParentViewController) {
        [self saveMetrics:@"VIDSelectYear_BackButtonClicked"];
    }
    [super viewWillDisappear:animated];
}

@end
