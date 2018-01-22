//
//  SettingsViewController.m
//  SingleEntry
//
//  Copyright © 2018 Socket Mobile. All rights reserved.
//

#import "SettingsViewController.h"
#import "SktCaptureHelper.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *softScanEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *d600SupportSwitch;
@end

@implementation SettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.softScanEnabledSwitch
     setOn:self.model.softScanEnabled
     animated:TRUE];
    [self.d600SupportSwitch setOn:self.model.d600Supported animated:TRUE];
    
    // get Capture version
    SKTCaptureHelper* capture = [SKTCaptureHelper sharedInstance];
    [capture getVersionWithCompletionHandler:^(SKTResult result, SKTCaptureVersion *version) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(result == SKTCaptureE_NOERROR){
                self.versionLabel.text = [NSString stringWithFormat:@"Capture version: %lu.%lu.%lu", version.Major, version.Middle, version.Minor];
            }
            else {
                self.versionLabel.text = [NSString stringWithFormat:@"Error %ld reading the version", result];
            }
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didChangeSoftScanSwitch:(id)sender {
    self.model.softScanEnabled = self.softScanEnabledSwitch.isOn;
}

- (IBAction)didChangeD600SupportSwitch:(id)sender {
    self.model.d600Supported = self.d600SupportSwitch.isOn;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
