//
//  ANWebGLDamageViewController.m
//  Claim Valet
//
//  Created by Quan Nguyen on 6/25/15.
//  Copyright (c) 2015 Audaexplore, a Solera company. All rights reserved.
//

#import "ANWebGLDamageViewController.h"
#import "ANWelcomeViewController.h"

@interface ANWebGLDamageViewController ()
@end

@implementation ANWebGLDamageViewController
@synthesize delegate;

-(void) showDamageView{
    NSString* fullPathToFolder = [[self getDocumentsPath] stringByAppendingPathComponent:@"Damage/index.html"];
    NSURL * url =[NSURL fileURLWithPath:fullPathToFolder];
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [self.wvWebGlViewer loadRequest:request];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.wvWebGlViewer = [[UIWebView alloc]initWithFrame:self.view.frame];
    self.wvWebGlViewer.scrollView.scrollEnabled = NO;
    self.wvWebGlViewer.scrollView.bounces = NO;
    self.wvWebGlViewer.delegate = self;
    
    self.wvWebGlViewer.hidden = YES;
    [self.view addSubview:self.wvWebGlViewer];
    
    // load from local file.
    [self showDamageView];
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}

-(void) removeWebView{
    [self.wvWebGlViewer loadHTMLString:@"" baseURL:nil];
    [self.wvWebGlViewer stopLoading];
    self.wvWebGlViewer.delegate =nil;
    [self.wvWebGlViewer removeFromSuperview];
    self.wvWebGlViewer = nil;
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.wvWebGlViewer.hidden = NO;
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *requestString = [[request URL] absoluteString];
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        NSLog(@"request : %@",requestString);
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        NSString *functionName = (NSString*)[components objectAtIndex:1];
        
        if([functionName isEqualToString:@"BackButtonClicked"]) {
            [self removeWebView];
            [delegate onBackClicked];
        } else if ([functionName isEqualToString:@"NextButtonClicked"]) {
            [self removeWebView];
            [delegate onNextClicked];
        } else if ([functionName isEqualToString:@"CancelButtonClicked"]) {
            [self removeWebView];
            [delegate onCancelClicked];
        } else if([functionName isEqualToString:@"GetObjFileNames"]) {
             int callbackId = [((NSString*)[components objectAtIndex:2]) intValue];
             [self getAllFileNameUnderCar:callbackId];
        }
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        return YES;
    }
    if ([requestString hasPrefix:@"saveimage:"]) {
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        NSString *imageString = (NSString*)[components objectAtIndex:2];
        NSString *fileName = (NSString*)[components objectAtIndex:1];
        NSLog(@"fileName : %@", fileName);
        NSData *fileData = [[NSData alloc] initWithBase64EncodedString:imageString options:0];
        
        //encrypt the image before writing to the device
        NSData *encryptedData = [self.globalInstance encrypt:fileData withKey:self.claim.claimNumber];
        [encryptedData writeToFile:[NSString stringWithFormat:@"%@/%@", [self getDocumentsPath], fileName] atomically:YES];
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        return NO;
    }
    if ([requestString hasPrefix:@"savestatistic:"]) {
        requestString = [requestString stringByReplacingOccurrencesOfString:@"savestatistic:"
                                             withString:@""];
        NSString *jsonArrayString = [requestString stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSData* statisticData = [jsonArrayString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *statisticArray = [NSJSONSerialization JSONObjectWithData:statisticData options:NSJSONReadingMutableContainers error:nil];
        NSMutableDictionary *claimInfo = [[NSMutableDictionary alloc] initWithCapacity:7];
        [claimInfo setObject:self.claim.lbObject[@"claimNumber"] forKey:@"ClaimNumber"];
        [claimInfo setObject:self.claim.lbObject[@"estimateVehicleVIN"] forKey:@"VIN"];
        [claimInfo setObject:self.claim.lbObject[@"estimateVehicleMake"] forKey:@"Make"];
        [claimInfo setObject:self.claim.lbObject[@"estimateVehicleModel"] forKey:@"Model"];
        [claimInfo setObject:self.claim.lbObject[@"vehicleFileId"] forKey:@"FileId"];
        [claimInfo setObject:self.claim.lbObject[@"vehicleStyleCode"] forKey:@"StyleCode"];
        [claimInfo setObject:self.claim.lbObject[@"estimateVehicleYear"] forKey:@"Year"];
        NSMutableDictionary *output = [[NSMutableDictionary alloc] initWithCapacity:2];
        [output setObject:claimInfo forKey:@"Claim_Info"];
        [output setObject:statisticArray forKey:@"Statistic"];
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:output
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (! jsonData) {
            NSLog(@"Can't save statistic.txt : %@", error);
        } else {
             [jsonData writeToFile:[NSString stringWithFormat:@"%@/%@", [self getDocumentsPath], @"statistic.txt"] atomically:YES];
        }
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
        return NO;
    }
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    return YES;
}


-(void)getAllFileNameUnderCar:(int)callbackId
{
    NSString *filePath = [NSString stringWithFormat:@"%@/Car/",[self getDocumentsPath]];
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:NULL];
    NSMutableArray *objFileNamesArray = [[NSMutableArray alloc] init];
    
    [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        NSString *extension = [[filename pathExtension] lowercaseString];
        if ([extension isEqualToString:@"obj"]) {
            [objFileNamesArray addObject:filename];
        }
    }];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objFileNamesArray options:0 error:nil];
    
    NSString *fileNamesString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
   [self.wvWebGlViewer stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"NativeBridge.resultForCallback(%d,%@);",callbackId,fileNamesString]];
  
    NSLog(@"%@",fileNamesString);
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if( [delegate respondsToSelector:@selector(setDamageViewerPresented:)] ){
        [delegate setDamageViewerPresented:NO];
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

@end
