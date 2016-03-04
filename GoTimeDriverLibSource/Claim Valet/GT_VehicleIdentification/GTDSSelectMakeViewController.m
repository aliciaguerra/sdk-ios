//
//  GTDSSelectMakeViewController.m
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/11/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSSelectMakeViewController.h"
#import "GTDSSelectModelViewController.h"

@interface GTDSSelectMakeViewController ()

@end

@implementation GTDSSelectMakeViewController

@synthesize tvMakes;
@synthesize receivedData;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self saveMetrics:@"VIDSelectMake_PageLoaded"];

    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.delegate = self;
        
    [self callGetMakeService: self.globalInstance.vehicleYear];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reduce the size of the table view for iPhone 4.
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        CGRect tableFrame = [self.tvMakes frame];
        tableFrame.size.height -= 88;
        [self.tvMakes setFrame:tableFrame];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) callGetMakeService:(NSString *) year
{
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    NSString *requestMessage = [ANWebServiceHelper getMakesRequestMessage:year];
    NSMutableURLRequest *theRequest = [ANWebServiceHelper getMessageRequest:requestMessage :self.globalInstance.ngpUsername :self.globalInstance.ngpPassword];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    [connection start];
    
}

#pragma James Xie -- NSURLConnectionDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength: 0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Request Error Message: %@", error);
    //try calling edmunds
    NSLog(@"Try Edmunds API for Makes");
    [self callEdmundsForMakes];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id result = [ANWebServiceHelper getJsonMessage:self.receivedData];
    if (result) {
        NSDictionary *object = result;
        NSLog(@"Makes Main Dictionary: %@", [object description]);
        
        if ([object valueForKey:@"Request"] != nil && [[object valueForKey:@"Request"] valueForKey:@"Error"] != nil) {
            NSLog(@"Error Message %@", [[object valueForKey:@"Request"] valueForKey:@"Message"]);
            NSLog(@"Try Edmunds API for Makes");
            [self callEdmundsForMakes];
            return;
        }
        [HUD hide:YES];
        makesArr = [[NSMutableArray alloc] init];
        
        NSMutableArray *currentMakesArr = [object valueForKey:@"Makes"];
        
        NSString *motorcyleMakes = self.globalInstance.suppressedVehicles;
        
        NSArray *motorcycleMakesArr = [motorcyleMakes componentsSeparatedByString:@","];
        
        for (NSString *currentMake in currentMakesArr)
        {
            BOOL isMotorCycle = NO;
            
            for (NSString *currentMotorcycle in motorcycleMakesArr)
            {
                if ([currentMotorcycle isEqualToString:currentMake])
                {
                    isMotorCycle = YES;
                }
            }
            
            if (isMotorCycle == NO)
            {
                [makesArr addObject:currentMake];
            }
        }
        
        self.globalInstance.isUsingEdmunds = NO;
        [tvMakes reloadData];
    } else {
        [self callEdmundsForMakes];
    }
}

#pragma mark - Table
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [makesArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil )
    {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [makesArr objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveMetrics:@"VIDSelectMake_Selected"];
    
    if ( ! [self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    
    self.globalInstance.vehicleMake = [makesArr objectAtIndex:indexPath.row];
    
    GTDSSelectModelViewController *viewController = [[GTDSSelectModelViewController alloc] initWithNibName:@"GTDSSelectModelViewController"];
    viewController.claim = self.claim;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"PLEASE SELECT A MAKE";
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)callEdmundsForMakes
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.edmunds.com/api/vehicle/v2/makes?fmt=json&year=%@&api_key=32hj79x57h9s2w6fcjane5at", self.globalInstance.vehicleYear];
 
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               [HUD hide:YES];
                               self.globalInstance.isUsingEdmunds = YES;
                               
                               NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                               long responseStatusCode = [httpResponse statusCode];
                               if( (responseStatusCode == 200) &&
                                  (data.length > 0) &&
                                  (connectionError == nil) ){
                                   
                                   NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                options:0
                                                                                                  error:NULL];
                                   
                                   // NSLog(@"Edmunds response for Makes: %@", responseData.description);
                                   
                                   NSMutableArray *makes = [responseData objectForKey:@"makes"];
                                   
                                   makesArr = [[NSMutableArray alloc] init];
                                   
                                   for (NSDictionary *makeDictionary in makes)
                                   {
                                       [makesArr addObject:[makeDictionary objectForKey:@"name"]];
                                   }
                                   [tvMakes reloadData];
                               } else {
                                   NSLog(@"Edmunds web service call failed.");
                               }
                           }];
}

- (IBAction)backClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.isMovingFromParentViewController) {
        [self saveMetrics:@"VIDSelectMake_BackButtonClicked"];
    }
    [super viewWillDisappear:animated];
}

@end
