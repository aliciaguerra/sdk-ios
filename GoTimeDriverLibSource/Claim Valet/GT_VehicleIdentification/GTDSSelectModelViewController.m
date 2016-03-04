//
//  GTDSSelectModelViewController.m
//  GTDSMaaco
//
//  Created by Anthony Doan on 6/11/14.
//  Copyright (c) 2014 AudaExplore. All rights reserved.
//

#import "GTDSSelectModelViewController.h"
#import "ANVehicleStyleMappingReader.h"
#import "AEVehicleInfoViewController.h"
#import "GTDSEdmundsAEBodyStyle.h"
#import "GTDSSelectStyleViewController.h"
#import "ANWelcomeViewController.h"
#import "ANUtils.h"
#import "ANWelcomeTextVehicleIdentifiedVC.h"

@interface GTDSSelectModelViewController ()
{
    NSURLConnection *getModelsResourceConnection;
    NSURLConnection *getStylesResourceConnection;
}
@end

@implementation GTDSSelectModelViewController

@synthesize tvModels;
@synthesize receivedData;

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
    [self saveMetrics:@"VIDSelectModel_PageLoaded"];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.delegate = self;
    
    NSString *requestMessage = [ANWebServiceHelper getModelsRequestMessage:self.globalInstance.vehicleYear :self.globalInstance.vehicleMake];
    getModelsResourceConnection = [self getRequestConnection:requestMessage];
    [getModelsResourceConnection start];
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.isMovingFromParentViewController) {
        [self saveMetrics:@"VIDSelectModel_BackButtonClicked"];
    }
    [super viewWillDisappear:animated];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reduce the size of the table view for iPhone 4.
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        CGRect tableFrame = [self.tvModels frame];
        tableFrame.size.height -= 88;
        [self.tvModels setFrame:tableFrame];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)stringWebServiceEndpoint
{
    return kAEInternetResourceAdaptor_WebServiceURL_Production;
}
#pragma James - NSURLConnectionDelegate

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
    [self errorProcess:connection];
}
-(void)errorProcess:(NSURLConnection *) connection
{
    if (connection == getModelsResourceConnection) {
        NSLog(@"Try Edmunds API For Models");
        [self callEdmundsForModels];
    } else if (connection == getStylesResourceConnection) {
        NSLog(@"Try Edmunds API For Vehicle Style");
        [self callEdmundsForVehicleStyle];
    }
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id result = [ANWebServiceHelper getJsonMessage:self.receivedData];
    if (result) {
        NSDictionary *object = result;
        NSLog(@"Makes Main Dictionary: %@", [object description]);
        
          if ([object valueForKey:@"Request"] != nil && [[object valueForKey:@"Request"] valueForKey:@"Error"] != nil)  {
             NSLog(@"Error Message %@", [[object valueForKey:@"Request"] valueForKey:@"Message"]);
            [self errorProcess:connection];
            return;
        }
        [self saveMetrics:@"VIDSelectModel_VehicleDataReceived_Autosource"];
        [HUD hide:YES];
        if (connection == getModelsResourceConnection)
        {
            NSDictionary *object = result;
            
            NSLog(@"Models Main Dictionary: %@", [object description]);
            
            modelsArr = [[NSMutableArray alloc] init];
            
            NSMutableArray *currentModelsArr = [object valueForKey:@"Models"];
            
            for (NSString *currentModel in currentModelsArr)
            {
                if (![currentModel isEqualToString:@"Motorcycle"])
                {
                    [modelsArr addObject:currentModel];
                }
            }
            [tvModels reloadData];
        } else if (connection == getStylesResourceConnection)
        {
            BOOL isCallingEdmunds = [self processStylesForRequest:result:connection];
            
            if (isCallingEdmunds == YES)
            {
                return;
            }
            
            if ([styleNamesArr count] == 0)
            {
                self.globalInstance.vehicleStyle = @"";
                [self goBackToWelcome];
                return;
            }
            
            GTDSSelectStyleViewController *viewController = [[GTDSSelectStyleViewController alloc] initWithNibName:@"GTDSSelectStyleViewController"];
            
            viewController.fileIDsArr = fileIDsArr;
            viewController.styleIDsArr = styleIDsArr;
            viewController.styleNamesArr = styleNamesArr;
            viewController.claim = self.claim;
            [self.navigationController pushViewController:viewController animated:YES];
        }
    } else {
        [self errorProcess:connection];
    }
}

#pragma mark - Table
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [modelsArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil )
    {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [modelsArr objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveMetrics:@"VIDSelectModel_Selected"];
    
    if ( ! [self connectedToInternet]) {
        [self showNotConnectedToInternetAlert];
        return;
    }
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.delegate = self;
    
    self.globalInstance.vehicleModel = [modelsArr objectAtIndex:indexPath.row];
    
    NSString *requestMessage = [ANWebServiceHelper getStylesRequestMessage:self.globalInstance.vehicleYear :self.globalInstance.vehicleMake :[modelsArr objectAtIndex:indexPath.row]];
    
    getStylesResourceConnection = [self getRequestConnection:requestMessage];
    
    [getStylesResourceConnection start];
}

-(NSURLConnection*) getRequestConnection:(NSString *) requestMessage {
    
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    NSMutableURLRequest *theRequest = [ANWebServiceHelper getMessageRequest:requestMessage :self.globalInstance.ngpUsername :self.globalInstance.ngpPassword];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    return connection;
    
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"PLEASE SELECT A MODEL";
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (BOOL) processStylesForRequest:(id)result :(NSURLConnection*) connection
{
    // We handle all three JSON formats possible in object below
    NSDictionary *object = result;
    NSLog(@"Main Dictionary: %@", [object description]);
    
    NSMutableArray *styles = [[NSMutableArray alloc] init];
    NSString *currentFileIDStr;
    
    NSMutableArray *currentStyles = nil;
    NSMutableDictionary *currentStyleDictionary = nil;
    
    if ([object valueForKey:@"Styles"] != nil)
    {
        currentStyles = [object valueForKey:@"Styles"];
        
        if ([currentStyles count] > 0)
        {
            currentStyleDictionary = [currentStyles objectAtIndex:0];
        }
    }
    
    // If FileID exists at top level of JSON, then we immediately retrieve it
    if( ([object valueForKey:@"FileID"] == nil || [[object valueForKey:@"FileID"] isMemberOfClass:[NSNull class]] )
       && ([object valueForKey:@"Styles"] == nil || (currentStyleDictionary != nil && [[currentStyleDictionary valueForKey:@"FileID"] isMemberOfClass:[NSNull class]]) ) )
    {
        [self errorProcess:connection];
        return YES;
    }
    else if ([object valueForKey:@"FileID"]) {
        currentFileIDStr = [object valueForKey:@"FileID"];
        [styles addObject:currentFileIDStr];
    } else {
        // Otherwise, there should be a Styles key
        styles = [object valueForKey:@"Styles"];
    }
    
    NSLog(@"Styles Array: %@", [styles objectAtIndex:0]);
    
    // If Styles includes keys for "Results", then we get each dictionary within "Results"
    NSMutableArray *stylesWithinResultsArr = [[NSMutableArray alloc] init];
    NSMutableArray *selectNamesArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary *currentDictionary in styles) {
        if ([currentDictionary isKindOfClass:[NSDictionary class]] && [currentDictionary valueForKey:@"Results"]) {
            NSMutableArray *currentResultsArr = [currentDictionary valueForKey:@"Results"];
            
            NSString *currentSelectName = [currentDictionary valueForKey:@"Select"];
            
            for (NSDictionary *resultsDictionary in currentResultsArr) {
                [stylesWithinResultsArr addObject:resultsDictionary];
                [selectNamesArr addObject:currentSelectName];
            }
        }
    }
    
    // if there are styles within the Results key
    if ([stylesWithinResultsArr count] > 0) {
        styles = [[NSMutableArray alloc] initWithArray:stylesWithinResultsArr];
    }
    
    fileIDsArr = [[NSMutableArray alloc] init];
    styleIDsArr = [[NSMutableArray alloc] init];
    styleNamesArr = [[NSMutableArray alloc] init];
    
    // If FileID is at the top level of JSON, then we have only one fileID or styleID
    if ([object valueForKey:@"FileID"]) {
        [fileIDsArr addObject:[currentFileIDStr substringWithRange:NSMakeRange(0, 4)]];
        [styleIDsArr addObject:[currentFileIDStr substringWithRange:NSMakeRange(4, 2)]];
    } else
    {
        int currentIndex = 0;
        
        for (NSDictionary *currentDictionary in styles)
        {
            if ([[currentDictionary objectForKey:@"FileID"] isMemberOfClass:[NSNull class]])
            {
                // [self internetResourceRequestDidFail:request];
                // return YES;
                ++currentIndex;
                continue;
            }
            
            if (currentIndex < [selectNamesArr count])
            {
                NSString *longStyleName = [NSString stringWithFormat:@"%@ %@",[currentDictionary objectForKey:@"Style"], [selectNamesArr objectAtIndex:currentIndex]];
                
                [styleNamesArr addObject:longStyleName];
            } else
            {
                [styleNamesArr addObject:[currentDictionary objectForKey:@"Style"]];
            }
            
            [fileIDsArr addObject:[[currentDictionary objectForKey:@"FileID"] substringWithRange:NSMakeRange(0, 4)]];
            [styleIDsArr addObject:[[currentDictionary objectForKey:@"FileID"] substringWithRange:NSMakeRange(4, 2)]];
            
            ++currentIndex;
        }
    }
    
    BOOL isCallingEdmunds = [self getBodyStyleDescriptions];
    
    if ([fileIDsArr count] > 0)
    {
        strFileID = [fileIDsArr objectAtIndex:0];
        strStyleID = [styleIDsArr objectAtIndex:0];
        strBodyStyleCode = [arrBodyStyleCodes objectAtIndex:0];
    }
    
    return isCallingEdmunds;
}

- (BOOL) getBodyStyleDescriptions {
    arrBodyStyleCodes = [[NSMutableArray alloc] init];
    arrUniqueFileIDs = [[NSMutableArray alloc] init];
    
    NSString *strFileID2 = @"";
    NSString *strStyleID2 = @"";
    
    if ([fileIDsArr count] > 0)
    {
        strFileID2 = [fileIDsArr objectAtIndex:0];
        strStyleID2 = [styleIDsArr objectAtIndex:0];
    }
    
    NSString *strBodyStyleCode2 = [ANUtils getBodyStyleFromServerForFileID:strFileID2 andStyleModel:strStyleID2];
    
    BOOL isCallingEdmunds = NO;
    
    if (strBodyStyleCode2 == nil) {
        strBodyStyleCode2 = @"";
        
        isCallingEdmunds = YES;
        
        // call Edmunds if fileId doesn't have a mapping
        [self callEdmundsForVehicleStyle];
    }
    
    [arrBodyStyleCodes addObject:strBodyStyleCode2];
    [arrUniqueFileIDs addObject:strFileID2];
    
    return isCallingEdmunds;
}

- (void)callEdmundsForModels
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.edmunds.com/api/vehicle/v2/makes?fmt=json&year=%@&api_key=32hj79x57h9s2w6fcjane5at", self.globalInstance.vehicleYear];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               [HUD hide:YES];
                               NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                               long responseStatusCode = [httpResponse statusCode];
                               if( (responseStatusCode == 200) &&
                                  (data.length > 0) &&
                                  (connectionError == nil) ){
                                   
                                   [self saveMetrics:@"VIDSelectModel_VehicleDataReceived_Edmunds"];
                                   NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                options:0
                                                                                                  error:NULL];
                                   
                                   // NSLog(@"Edmunds response for Models: %@", responseData.description);
                                   
                                   NSMutableArray *makes = [responseData objectForKey:@"makes"];
                                   
                                   modelsArr = [[NSMutableArray alloc] init];
                                   
                                   for (NSDictionary *makeDictionary in makes)
                                   {
                                       if ([[makeDictionary objectForKey:@"name"] isEqualToString:self.globalInstance.vehicleMake])
                                       {
                                           NSMutableArray *models = [makeDictionary objectForKey:@"models"];
                                           
                                           for (NSDictionary *modelDictionary in models)
                                           {
                                                [modelsArr addObject:[modelDictionary objectForKey:@"name"]];
                                           }
                                       }
                                       
                                   }
                                   [tvModels reloadData];
                               } else {
                                   NSLog(@"Edmunds web service call failed.");
                               }
                           }];
}

- (void)callEdmundsForVehicleStyle
{
    NSString *urlString = [NSString stringWithFormat:@"https://api.edmunds.com/api/vehicle/v2/%@/%@/%@/styles?fmt=json&api_key=32hj79x57h9s2w6fcjane5at", [self.globalInstance.vehicleMake stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self.globalInstance.vehicleModel stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self.globalInstance.vehicleYear stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
                                   [self saveMetrics:@"VIDSelectModel_VehicleDataReceived_Edmunds"];
                                   
                                   NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                options:0
                                                                                                  error:NULL];
                                   
                                   NSLog(@"Style response: %@", responseData.description);
                                   
                                   NSMutableArray *styles = [responseData valueForKey:@"styles"];
                                   
                                   if ([styles count] == 0)
                                   {
                                       self.globalInstance.vehicleStyle = @"";
                                       
                                       [self goBackToWelcome];
                                       return;
                                   }
                                   
                                   edmundsStyleIDsArr = [[NSMutableArray alloc] init];
                                   edmundsStyleNamesArr = [[NSMutableArray alloc] init];
                                   
                                   // get all styleIds and styleNames
                                   for (NSDictionary *currentDictionary in styles)
                                   {
                                       NSNumber *currentStyleId = [currentDictionary valueForKey:@"id"];
                                       NSString *currentStyleName = [currentDictionary valueForKey:@"name"];
                                       
                                       [edmundsStyleIDsArr addObject:currentStyleId];
                                       [edmundsStyleNamesArr addObject:currentStyleName];
                                   }
                                   
                                   GTDSSelectStyleViewController *viewController = [[GTDSSelectStyleViewController alloc] initWithNibName:@"GTDSSelectStyleViewController"];
                                   
                                   viewController.fileIDsArr = fileIDsArr;
                                   viewController.styleIDsArr = styleIDsArr;
                                   viewController.styleNamesArr = styleNamesArr;
                                   viewController.edmundsStyleIDsArr = edmundsStyleIDsArr;
                                   viewController.edmundsStyleNamesArr = edmundsStyleNamesArr;
                                   viewController.claim = self.claim;
                                   
                                   UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Model" style:UIBarButtonItemStylePlain target:nil action:nil];
                                   self.navigationItem.backBarButtonItem=backButton;
                                   
                                   [HUD hide:YES];
                                   
                                   [self.navigationController pushViewController:viewController animated:YES];
                               }
                               else {
                                   NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                                   
                                   NSLog(@"Edmunds web service call for vehicle style failed.");
                                   NSLog(@"Response data: %@", httpResponse.description);
                                   NSLog(@"Connection Error: %@", connectionError.description);
                               }
                           }];
}

- (IBAction)backClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) goBackToWelcome
{
    self.claim.fileID = strFileID == nil ? @"" : strFileID;
    self.claim.clipCode = strBodyStyleCode == nil ? @"" : strBodyStyleCode;
    self.claim.yearMakeModel = [NSString stringWithFormat:@"%@ %@ %@", self.globalInstance.vehicleYear , self.globalInstance.vehicleMake, self.globalInstance.vehicleModel];
    
    // Save vehicle information to the claim on Parse.
    [self.claim.lbObject setObject:self.globalInstance.vehicleYear forKey:@"estimateVehicleYear"];
    [self.claim.lbObject setObject:self.globalInstance.vehicleMake forKey:@"estimateVehicleMake"];
    [self.claim.lbObject setObject:self.globalInstance.vehicleModel forKey:@"estimateVehicleModel"];
    [self.claim.lbObject setObject:@"" forKey:@"estimateVehicleVIN"];
    
    [self.claim.lbObject setObject:(strFileID == nil || strFileID.length != 4 ? @"" : strFileID) forKey:@"vehicleFileId"];
    [self.claim.lbObject setObject:(strStyleID == nil || strStyleID.length != 2 ? @"" : strStyleID) forKey:@"vehicleStyleCode"];
    [self saveClaimToServer];
    [HUD hide:YES];
    
    NSString *welcomeText = @"Your vehicle has been identified";
    NSString *startButtonText = @"Continue";
    
    if([self.globalInstance damageViewerEnabled] && self.globalInstance.bVideoInstruction) {
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

@end
