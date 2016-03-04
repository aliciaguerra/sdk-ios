//
//  GTDSSelectStyleViewController.m
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/13/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSSelectStyleViewController.h"
#import "AEVehicleInfoViewController.h"
#import "ANVehicleStyleMappingReader.h"
#import "GTDSEdmundsAEBodyStyle.h"
#import "ANWelcomeViewController.h"
#import "ANUtils.h"
#import "ANWelcomeTextVehicleIdentifiedVC.h"

@interface GTDSSelectStyleViewController ()

@end

@implementation GTDSSelectStyleViewController

@synthesize fileIDsArr;
@synthesize styleNamesArr;
@synthesize styleIDsArr;
@synthesize fileIDStr;
@synthesize styleIDStr;
@synthesize bodyStyleCodeStr;
@synthesize edmundsStyleNamesArr;
@synthesize edmundsStyleIDsArr;

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
    [self saveMetrics:@"VIDSelectStyle_PageLoaded"];
    
    self.showSmallFont = NO;
    
    for (NSString *styleNameStr in self.styleNamesArr)
    {
        if ([styleNameStr length] > 25)
        {
            self.showSmallFont = YES;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.isMovingFromParentViewController) {
        [self saveMetrics:@"VIDSelectStyle_BackButtonClicked"];
    }
    [super viewWillDisappear:animated];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reduce the size of the table view for iPhone 4.
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        CGRect tableFrame = [self.tvStyles frame];
        tableFrame.size.height -= 88;
        [self.tvStyles setFrame:tableFrame];
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
    if ([self.edmundsStyleNamesArr count] > 0)
    {
        return [self.edmundsStyleNamesArr count];
    }
    
    return [self.styleNamesArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil )
    {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if ([self.edmundsStyleNamesArr count] > 0)
    {
        cell.textLabel.text = [self.edmundsStyleNamesArr objectAtIndex:indexPath.row];
    } else
    {
        cell.textLabel.text = [self.styleNamesArr objectAtIndex:indexPath.row];
    }
    
    if (self.showSmallFont == YES)
    {
        cell.textLabel.font = [UIFont systemFontOfSize:12.0];
    } else
    {
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveMetrics:@"VIDSelectStyle_Selected"];
    
    if ( ! [self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.animationType = MBProgressHUDModeIndeterminate;
    
    dispatch_queue_t moveToOtherScreen = dispatch_queue_create("MoveToOtherScreen", NULL);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, moveToOtherScreen, ^(void){
        [self performSelectorOnMainThread:@selector(moveToWelcomeScreenForIndexPath:) withObject:indexPath waitUntilDone:NO];
    });
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"PLEASE SELECT A STYLE";
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void) getBodyStyleDescriptionsForSelectedStyleIndex:(NSIndexPath *) indexPath
{
    NSString *strFileID = [fileIDsArr objectAtIndex:indexPath.row];
    NSString *strStyleID = [styleIDsArr objectAtIndex:indexPath.row];
    NSString *strBodyStyleCode = [ANUtils getBodyStyleFromServerForFileID:strFileID andStyleModel:strStyleID];
    
    if (strBodyStyleCode == nil)
    {
        strBodyStyleCode = @"";
    }
    
    self.fileIDStr = strFileID;
    self.styleIDStr = strStyleID;
    self.bodyStyleCodeStr = strBodyStyleCode;
    
    NSLog(@"FileID: %@ BodyStyleCode: %@ StyleName: %@", self.fileIDStr, self.bodyStyleCodeStr, [styleNamesArr objectAtIndex:indexPath.row]);
}

- (void)callEdmundsForVehicleStyleDetail:(NSString *)vehicleStyleId
{
    NSString *urlString = [NSString stringWithFormat:@"https://api.edmunds.com/api/vehicle/v2/styles/%@?view=full&fmt=json&api_key=32hj79x57h9s2w6fcjane5at", [vehicleStyleId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                               long responseStatusCode = [httpResponse statusCode];
                               if( (responseStatusCode == 200) &&
                                  (data.length > 0) &&
                                  (connectionError == nil) ){
                                   [self saveMetrics:@"VIDSelectStyle_VehicleDataReceived_Edmunds"];
                                   
                                   NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                options:0
                                                                                                  error:NULL];
                                   
                                   NSLog(@"Style response: %@", responseData.description);
                                   
                                   NSDictionary *categoryEntries = [responseData objectForKey:@"categories"];
                                   NSString *vehicleStyle = [categoryEntries objectForKey:@"vehicleStyle"];
                                   
                                   NSString *numDoors = [responseData objectForKey:@"numOfDoors"];
                                   
                                   //GTDSEdmundsAEBodyStyle *edmundsAEMapper = [[GTDSEdmundsAEBodyStyle alloc] initClipCodeMappingsWithFile:@"Edmunds_AE_BodyStyles"];
                                   NSString *edmundsKey = [NSString stringWithFormat:@"%@%@", numDoors, vehicleStyle];
                                   //remove the white spaces in the keys
                                   edmundsKey = [edmundsKey stringByReplacingOccurrencesOfString:@" " withString:@""];
                                   //NSString *aeBodyStyle = [edmundsAEMapper getAEBodyStyleForEdmundsStyle:edmundsKey];
                                   
                                   self.globalInstance.vehicleStyle = vehicleStyle;
                                   
                                   [HUD hide:YES];
                                   
                                   [self goBackToWelcomeWithVehicleDescription];
                               }
                               else {
                                   NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                                   
                                   NSLog(@"Edmunds web service call for vehicle style detail failed.");
                                   NSLog(@"Response data: %@", httpResponse.description);
                                   NSLog(@"Connection Error: %@", connectionError.description);
                                   
                                   [HUD hide:YES];
                               }
                           }];
}

- (IBAction)backClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) goBackToWelcomeWithVehicleDescription
{
    self.claim.fileID = self.fileIDStr == nil ? @"" : self.fileIDStr;
    self.claim.clipCode = self.bodyStyleCodeStr == nil ? @"" : self.bodyStyleCodeStr;
    self.claim.yearMakeModel = [NSString stringWithFormat:@"%@ %@ %@", self.globalInstance.vehicleYear , self.globalInstance.vehicleMake, self.globalInstance.vehicleModel];
    
    // Save vehicle information to the claim on Parse.
    [self.claim.lbObject setObject:self.globalInstance.vehicleYear forKey:@"estimateVehicleYear"];
    [self.claim.lbObject setObject:self.globalInstance.vehicleMake forKey:@"estimateVehicleMake"];
    [self.claim.lbObject setObject:self.globalInstance.vehicleModel forKey:@"estimateVehicleModel"];
    [self.claim.lbObject setObject:@"" forKey:@"estimateVehicleVIN"];
    [self.claim.lbObject setObject:(self.fileIDStr == nil || self.fileIDStr.length != 4 ? @"" : self.fileIDStr) forKey:@"vehicleFileId"];
    [self.claim.lbObject setObject:(self.styleIDStr == nil || self.styleIDStr.length != 2 ? @"" : self.styleIDStr) forKey:@"vehicleStyleCode"];
    [self saveClaimToServer];
    
    NSString *welcomeText = @"Your vehicle has been identified";
    NSString *startButtonText = @"Continue";
    
    if( [self.globalInstance damageViewerEnabled] && self.globalInstance.bVideoInstruction) {
        ANWelcomeViewController *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified4"];
        } else {
            viewController = [[ANWelcomeViewController alloc] initWithNibName:@"ANWelcomeVehicleIdentified"];
        }
        viewController.navigationItem.hidesBackButton = YES;
        viewController.bShouldDownloadGraphic = YES;
        viewController.claim = self.claim;
        viewController.strWelcomeText = welcomeText;
        viewController.strStartButtonText = startButtonText;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        ANWelcomeTextVehicleIdentifiedVC *viewController;
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC4"];
        } else {
            viewController = [[ANWelcomeTextVehicleIdentifiedVC alloc] initWithNibName:@"ANWelcomeTextVehicleIdentifiedVC"];
        }
        viewController.navigationItem.hidesBackButton = YES;
        viewController.claim = self.claim;
        viewController.bShouldDownloadGraphic = YES;
        viewController.strWelcomeText = welcomeText;
        viewController.strStartButtonText = startButtonText;
        [self.navigationController pushViewController:viewController animated:YES];
    }
    
}

- (void)moveToWelcomeScreenForIndexPath:(NSIndexPath *)indexPath  {
    if ([self.edmundsStyleNamesArr count] > 0)
    {
        [self callEdmundsForVehicleStyleDetail:[NSString stringWithFormat:@"%ld", (long)[((NSNumber *)[self.edmundsStyleIDsArr objectAtIndex:indexPath.row]) integerValue]]];
        return;
    }
    
    [self saveMetrics:@"VIDSelectStyle_VehicleDataReceived_Autosource"];
    
    [self getBodyStyleDescriptionsForSelectedStyleIndex:indexPath];
    
    self.globalInstance.vehicleStyle = [self.styleNamesArr objectAtIndex:indexPath.row];
    
    [self goBackToWelcomeWithVehicleDescription];
    
    [HUD hide:YES];
}

@end
