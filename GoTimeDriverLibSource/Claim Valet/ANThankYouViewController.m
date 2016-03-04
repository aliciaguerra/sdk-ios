//
//  ANThankYouViewController.m
//  Self-ServiceEstimateDriver
//
//  Created by Quan Nguyen on 8/6/15.
//  Copyright (c) 2015 Quan Nguyen. All rights reserved.
//

#import "ANThankYouViewController.h"
#import "ANUtils.h"

@interface ANThankYouViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblThanksAgain;

@property (strong, nonatomic) IBOutlet UIView *vwYourOpinion;
@property (strong, nonatomic) IBOutlet UIView *vwQuestion1;
@property (strong, nonatomic) IBOutlet UIView *vwQuestion2;
@property (strong, nonatomic) IBOutlet UIView *vwQuestion3;
@property (strong, nonatomic) IBOutlet UIView *vwThankYou;

@property (nonatomic, strong) IBOutlet UIButton *btnQ1Star1;
@property (nonatomic, strong) IBOutlet UIButton *btnQ1Star2;
@property (nonatomic, strong) IBOutlet UIButton *btnQ1Star3;
@property (nonatomic, strong) IBOutlet UIButton *btnQ1Star4;
@property (nonatomic, strong) IBOutlet UIButton *btnQ1Star5;

@property (nonatomic, strong) IBOutlet UIButton *btnQ2Star1;
@property (nonatomic, strong) IBOutlet UIButton *btnQ2Star2;
@property (nonatomic, strong) IBOutlet UIButton *btnQ2Star3;
@property (nonatomic, strong) IBOutlet UIButton *btnQ2Star4;
@property (nonatomic, strong) IBOutlet UIButton *btnQ2Star5;

@property (nonatomic, strong) IBOutlet UIButton *btnQ3Star1;
@property (nonatomic, strong) IBOutlet UIButton *btnQ3Star2;
@property (nonatomic, strong) IBOutlet UIButton *btnQ3Star3;
@property (nonatomic, strong) IBOutlet UIButton *btnQ3Star4;
@property (nonatomic, strong) IBOutlet UIButton *btnQ3Star5;

@property (nonatomic, readwrite) int q1StarRating;
@property (nonatomic, readwrite) int q2StarRating;
@property (nonatomic, readwrite) int q3StarRating;

@property (strong, nonatomic) IBOutlet UILabel *lblBodyText;
@end

@implementation ANThankYouViewController
@synthesize vwYourOpinion;
@synthesize vwQuestion1;
@synthesize vwQuestion2;
@synthesize vwQuestion3;
@synthesize vwThankYou;
@synthesize lblBodyText;

- (IBAction)doneSelfServiceEstimate:(UIButton *)sender {
    [self saveMetrics:@"ThankYou_Done_ButtonClicked"];
    [self returnToHostApp];
}

- (IBAction)takeSurveyYesClicked:(UIButton *)sender {
    [self saveMetrics:@"ThankYou_Survey_ButtonClicked"];
    
    NSMutableArray * selectedButtons = nil;
    NSMutableArray * hiddenViews = [[NSMutableArray alloc] init];
    [hiddenViews addObject:self.vwYourOpinion];
    [hiddenViews addObject:self.vwQuestion1];
    [hiddenViews addObject:self.vwQuestion2];
    [hiddenViews addObject:self.vwQuestion3];
    [hiddenViews addObject:self.vwThankYou];
    
    UIView * animateView = self.vwYourOpinion;
    UIView * showView = self.vwQuestion1;
    
    [self showHideViews:animateView buttonsToSelect:selectedButtons viewsToHide:hiddenViews viewToShow:showView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self saveMetrics:@"ThankYou_PageLoaded"];
    self.metricPrefix = @"ThankYou";
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.rightBarButtonItem = nil;
    [self.navigationItem setHidesBackButton:YES animated:YES];
}

- (void) saveQuestionnaireToServer {
    [self saveMetrics:@"ThankYou_Survey_Complete"];
    NSMutableDictionary *parameters= [[NSMutableDictionary alloc] init];
    
    if (self.claim && self.claim.lbObject) {
        if (self.claim.lbObject[@"id"]) {
            [parameters setObject:self.claim.lbObject[@"id"] forKey:@"claim_objectId"];
        }
        if (self.claim.lbObject[@"orgId"]) {
            [parameters setObject:self.claim.lbObject[@"orgId"] forKey:@"orgId"];
        }
    }
    [parameters setObject:@{@"q1rating":[NSNumber numberWithInt:self.q1StarRating],
                            @"q2rating":[NSNumber numberWithInt:self.q2StarRating],
                            @"q3rating":[NSNumber numberWithInt:self.q3StarRating]} forKeyedSubscript:@"questionsRatings"];
    [parameters setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] forKey:@"appName"];
    [[self.globalInstance loopBackAPIHelper] callMobileBackEnd:SURVEYDATA_MODEL_NAME
                                            methodName:@"saveWithSuccess"
                                            parameters:parameters
                                               success:^(id value) {
                                                   NSLog(@"Save SurveyData to server successful.");
                                               } failure:^(NSError *error) {
                                                   [ANUtils errorHandle:error withLogMessage:@"Can't save survey data"];
                                               }];
}

- (void) showHideViews:(UIView *)viewToAnimate buttonsToSelect:(NSMutableArray *)selectedButtons viewsToHide:(NSMutableArray *)hiddenViews viewToShow:(UIView *)showView {
    CATransition* transition = [ANUtils getTransitionFromRight];
    UIImage *selectedStart = [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/selected_star.png", AUDAEXPLORE_GTD_BUNDLE]];
    
    [UIView transitionWithView:viewToAnimate duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        if(selectedButtons != nil && [selectedButtons count] > 0) {
                            for(UIButton *selectedButton in selectedButtons) {
                                [selectedButton setBackgroundImage:selectedStart forState:UIControlStateNormal];
                            }
                        }
                    }
                    completion:^(BOOL finished){
                        if(hiddenViews != nil && [hiddenViews count] > 0) {
                            for(UIView *viewToHide in hiddenViews) {
                                if(viewToHide != showView) {
                                    if(viewToHide == viewToAnimate) {
                                        [viewToHide.layer addAnimation:transition forKey:nil];
                                    }
                                    [viewToHide setHidden:YES];
                                }
                            }
                        }

                        [showView.layer addAnimation:transition forKey:nil];
                        [showView setHidden:NO];
                    }];
}

- (IBAction)starRatingClicked:(UIButton *)sender {
    NSMutableArray * selectedButtons = [[NSMutableArray alloc] init];
    NSMutableArray * hiddenViews = [[NSMutableArray alloc] init];
    [hiddenViews addObject:self.vwYourOpinion];
    [hiddenViews addObject:self.vwQuestion1];
    [hiddenViews addObject:self.vwQuestion2];
    [hiddenViews addObject:self.vwQuestion3];
    [hiddenViews addObject:self.vwThankYou];
    
    UIView * animateView = nil;
    UIView * showView = nil;
    
    if ([sender isEqual:self.btnQ1Star1]) {
        self.q1StarRating = 1;
        animateView = self.vwQuestion1;
        showView = self.vwQuestion2;
        [selectedButtons addObject:self.btnQ1Star1];
    } else if ([sender isEqual:self.btnQ1Star2]) {
        self.q1StarRating = 2;
        animateView = self.vwQuestion1;
        showView = self.vwQuestion2;
        [selectedButtons addObject:self.btnQ1Star1];
        [selectedButtons addObject:self.btnQ1Star2];
    } else if ([sender isEqual:self.btnQ1Star3]) {
        self.q1StarRating = 3;
        animateView = self.vwQuestion1;
        showView = self.vwQuestion2;
        [selectedButtons addObject:self.btnQ1Star1];
        [selectedButtons addObject:self.btnQ1Star2];
        [selectedButtons addObject:self.btnQ1Star3];
    } else if ([sender isEqual:self.btnQ1Star4]) {
        self.q1StarRating = 4;
        animateView = self.vwQuestion1;
        showView = self.vwQuestion2;
        [selectedButtons addObject:self.btnQ1Star1];
        [selectedButtons addObject:self.btnQ1Star2];
        [selectedButtons addObject:self.btnQ1Star3];
        [selectedButtons addObject:self.btnQ1Star4];
    } else if ([sender isEqual:self.btnQ1Star5]) {
        self.q1StarRating = 5;
        animateView = self.vwQuestion1;
        showView = self.vwQuestion2;
        [selectedButtons addObject:self.btnQ1Star1];
        [selectedButtons addObject:self.btnQ1Star2];
        [selectedButtons addObject:self.btnQ1Star3];
        [selectedButtons addObject:self.btnQ1Star4];
        [selectedButtons addObject:self.btnQ1Star5];
    } else if ([sender isEqual:self.btnQ2Star1]) {
        self.q2StarRating = 1;
        animateView = self.vwQuestion2;
        showView = self.vwQuestion3;
        [selectedButtons addObject:self.btnQ2Star1];
    } else if ([sender isEqual:self.btnQ2Star2]) {
        self.q2StarRating = 2;
        animateView = self.vwQuestion2;
        showView = self.vwQuestion3;
        [selectedButtons addObject:self.btnQ2Star1];
        [selectedButtons addObject:self.btnQ2Star2];
    } else if ([sender isEqual:self.btnQ2Star3]) {
        self.q2StarRating = 3;
        animateView = self.vwQuestion2;
        showView = self.vwQuestion3;
        [selectedButtons addObject:self.btnQ2Star1];
        [selectedButtons addObject:self.btnQ2Star2];
        [selectedButtons addObject:self.btnQ2Star3];
    } else if ([sender isEqual:self.btnQ2Star4]) {
        self.q2StarRating = 4;
        animateView = self.vwQuestion2;
        showView = self.vwQuestion3;
        [selectedButtons addObject:self.btnQ2Star1];
        [selectedButtons addObject:self.btnQ2Star2];
        [selectedButtons addObject:self.btnQ2Star3];
        [selectedButtons addObject:self.btnQ2Star4];
    } else if ([sender isEqual:self.btnQ2Star5]) {
        self.q2StarRating = 5;
        animateView = self.vwQuestion2;
        showView = self.vwQuestion3;
        [selectedButtons addObject:self.btnQ2Star1];
        [selectedButtons addObject:self.btnQ2Star2];
        [selectedButtons addObject:self.btnQ2Star3];
        [selectedButtons addObject:self.btnQ2Star4];
        [selectedButtons addObject:self.btnQ2Star5];
    } else if ([sender isEqual:self.btnQ3Star1]) {
        self.q3StarRating = 1;
        [self saveQuestionnaireToServer];
        animateView = self.vwQuestion3;
        showView = self.vwThankYou;
        [self updateBodyText];
        [selectedButtons addObject:self.btnQ3Star1];
    } else if ([sender isEqual:self.btnQ3Star2]) {
        self.q3StarRating = 2;
        [self saveQuestionnaireToServer];
        animateView = self.vwQuestion3;
        showView = self.vwThankYou;
        [self updateBodyText];
        [selectedButtons addObject:self.btnQ3Star1];
        [selectedButtons addObject:self.btnQ3Star2];
    } else if ([sender isEqual:self.btnQ3Star3]) {
        self.q3StarRating = 3;
        [self saveQuestionnaireToServer];
        animateView = self.vwQuestion3;
        showView = self.vwThankYou;
        [self updateBodyText];
        [selectedButtons addObject:self.btnQ3Star1];
        [selectedButtons addObject:self.btnQ3Star2];
        [selectedButtons addObject:self.btnQ3Star3];
    } else if ([sender isEqual:self.btnQ3Star4]) {
        self.q3StarRating = 4;
        [self saveQuestionnaireToServer];
        animateView = self.vwQuestion3;
        showView = self.vwThankYou;
        [self updateBodyText];
        [selectedButtons addObject:self.btnQ3Star1];
        [selectedButtons addObject:self.btnQ3Star2];
        [selectedButtons addObject:self.btnQ3Star3];
        [selectedButtons addObject:self.btnQ3Star4];
    } else if ([sender isEqual:self.btnQ3Star5]) {
        self.q3StarRating = 5;
        [self saveQuestionnaireToServer];
        animateView = self.vwQuestion3;
        showView = self.vwThankYou;
        [self updateBodyText];
        [selectedButtons addObject:self.btnQ3Star1];
        [selectedButtons addObject:self.btnQ3Star2];
        [selectedButtons addObject:self.btnQ3Star3];
        [selectedButtons addObject:self.btnQ3Star4];
        [selectedButtons addObject:self.btnQ3Star5];
    }
    
    [self showHideViews:animateView buttonsToSelect:selectedButtons viewsToHide:hiddenViews viewToShow:showView];
}

-(void)updateBodyText {
    lblBodyText.text = @"Your appraiser will contact you within one business day to review your photos and estimate.";
}

@end
