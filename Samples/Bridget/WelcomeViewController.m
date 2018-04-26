//
//  WelcomeViewController.m
//  Bridget
//
//  Created by Andrew Zimmer on 4/11/18.
//  Copyright © 2018 Occipital. All rights reserved.
//

#import <BridgeEngine/BridgeEngine.h>
#import "AppDelegate.h"
#import "WelcomeViewController.h"

@interface WelcomeViewController () <BEDebugSettingsDelegate>
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundView.layer.cornerRadius = 5.0;

    // Detect first-run and explicitly set the default settings.
    BOOL hasAppliedSettingsOnFirstRun = [BEAppSettings booleanValueFromAppSetting:SETTING_FIRST_RUN defaultValueIfSettingIsNotInBundle:NO];
    if(hasAppliedSettingsOnFirstRun == NO) {
        [BEAppSettings setBooleanValue:YES forAppSetting:SETTING_FIRST_RUN];
        [(AppDelegate *)UIApplication.sharedApplication.delegate resetSettingsToDefaults];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Events

- (IBAction)settingsTapped:(id)sender {
    NSBundle *beBundle = [NSBundle bundleForClass:BEDebugSettingsViewController.class];
    UIStoryboard *beDebugSettingsStoryboard = [UIStoryboard storyboardWithName:@"BEDebugSettings" bundle:beBundle];
    UINavigationController *navController = [beDebugSettingsStoryboard instantiateInitialViewController];
    BEDebugSettingsViewController *debugSettingsVC = (BEDebugSettingsViewController *)navController.viewControllers.firstObject;
    debugSettingsVC.delegate = self;
    [(AppDelegate *)UIApplication.sharedApplication.delegate prepareDebugSettingsVC:debugSettingsVC];
    
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - BEDebugSettingsDelegate

- (void) resetSettingsToDefaults {
    [(AppDelegate *)UIApplication.sharedApplication.delegate resetSettingsToDefaults];
}

- (void) debugSettingsBegin {
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"start" sender:nil];
    }];
}

@end
