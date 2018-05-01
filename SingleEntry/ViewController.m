//
//  ViewController.m
//  SingleEntry
//
//  Copyright © 2018 Socket Mobile. All rights reserved.
//

#import "ViewController.h"
#import "SettingsViewController.h"
#import "SktCaptureHelper.h"
#import "SettingsModel.h"
@interface ViewController () <SKTCaptureHelperDelegate>
{
}
@property (nonatomic, strong) SettingsModel* settings;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *triggerButton;
@property (weak, nonatomic) IBOutlet UITextField *decodedDataTextField;

@property (weak, nonatomic) SKTCaptureHelperDevice* softScan;
@property (weak, nonatomic) SKTCaptureHelperDeviceManager* deviceManager;
@end

@implementation ViewController

// segue used when closing the settings view
- (IBAction)unwindSegueToMainView:(UIStoryboardSegue *)unwindSegue {
    if ([unwindSegue.sourceViewController isKindOfClass:[SettingsViewController class]]){
        SKTCaptureHelper* capture = [SKTCaptureHelper sharedInstance];
        SKTCaptureSoftScan status = SKTCaptureSoftScanDisable;
        if (self.settings.softScanEnabled) {
            status = SKTCaptureSoftScanEnable;
        }
        [capture setSoftScanStatus:status completionHandler:^(SKTResult result) {
            NSLog(@"settings SoftScan returns: %ld", result);
        }];
        
        NSString* d600Favorites = @"";
        if (self.settings.d600Supported) {
            d600Favorites = @"*";
        }
        [_deviceManager setFavoriteDevices:d600Favorites completionHandler:^(SKTResult result) {
            NSLog(@"setting Favorites to %@ returns: %ld", d600Favorites, result);
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.triggerButton.hidden=YES;
    self.settings = [SettingsModel new];
    self.settings.softScanEnabled = FALSE;
    self.settings.d600Supported = FALSE;
    self.deviceManager = nil;
    
    // Fill out the AppInfo with the
    // developer ID, App Bundle ID, AppKey
    // coming from the Socket Mobile developer
    // portal when registering your application
    // for an AppKey
    SKTAppInfo* appInfo = [SKTAppInfo new];
    appInfo.AppID = @"ios:com.socketmobile.SingleEntry";
    appInfo.DeveloperID = @"bb57d8e1-f911-47ba-b510-693be162686a";
    appInfo.AppKey = @"MCwCFAcji6oT1soQeryg+x4Eh65bGNx2AhRtuPKEJ7aHWXKvv8hNVB291CYztQ==";
    SKTCaptureHelper* capture = [SKTCaptureHelper sharedInstance];
    [capture pushDelegate:self];
    [capture openWithAppInfo:appInfo completionHandler:^(SKTResult result) {
        NSLog(@"Opening Capture returns: %ld", result);
        if (!SKTSUCCESS(result)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = [NSString stringWithFormat:@"Error opening Capture: %ld", result];
            });

        } else {
            [capture getSoftScanStatusWithConfirmationHandler:^(SKTResult result, SKTCaptureSoftScan status) {
                if (status == SKTCaptureSoftScanEnable) {
                    self.settings.softScanEnabled = TRUE;
                }
            }];
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pressOnTriggerScan:(id)sender {
    
    if(self.softScan) {
        [self.softScan setTrigger:SKTCaptureTriggerStart completionHandler:^(SKTResult result) {
            NSLog(@"SetTrigger returns: %ld", result);
        }];
    }
}

#pragma mark - Utility methods
// update the connection status
// by getting the list of capture devices
// from capture and displaying each of their friendly name
-(void) updateStatus {
    SKTCaptureHelper* capture = [SKTCaptureHelper sharedInstance];
    NSArray* devices = [capture getDevicesList];
    NSString* newStatus = @"";
    if (devices.count == 0 ){
        newStatus = @"Waiting for a scanner...";
    } else {
        for (SKTCaptureHelperDevice* device in devices) {
            if( newStatus.length > 0) {
                newStatus = [newStatus stringByAppendingString: @", "];
            }
            newStatus = [newStatus stringByAppendingString: device.friendlyName];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = newStatus;
    });

}

// segue to the Settings view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier compare:@"settingsSegue"] == NSOrderedSame) {
        SettingsViewController* settings = [segue destinationViewController];
        settings.model = self.settings;
    }
}

#pragma mark - SettingsModelDelegate
-(void)updateSettings:(SettingsModel*)settings{
    
}
#pragma mark - SKTCaptureHelperDelegate

/**
 * called when a device has connected to the host
 *
 * @param device identifies the device that has just connected
 * @param result contains an error if something went wrong during the device connection
 */
-(void)didNotifyArrivalForDevice:(SKTCaptureHelperDevice*) device withResult:(SKTResult) result {
    NSLog(@"didNotifyArrivalForDevice");
    if (SKTSUCCESS(result)) {
        [self updateStatus];
        
        // for a SoftScan scanner, enable the Softscan trigger
        // button, and set the overlay view parameter
        if(device.deviceType == SKTCaptureDeviceTypeSoftScan){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.triggerButton.hidden = NO;
            });
            self.softScan = device;
            NSMutableDictionary* overlayParameter=[[NSMutableDictionary alloc]init];
            [overlayParameter setValue:self forKey:SKTCaptureSoftScanContext];
            [device setOverlayView:overlayParameter completionHandler:^(SKTResult result) {
                NSLog(@"Settings the SoftScan Overlay view returns: %ld", result);
            }];
        }
    }
}

/**
 * called when a device has disconnected from the host
 *
 * @param device identifies the device that has just disconnected
 * @param result contains an error if something went wrong during the device disconnection
 */
-(void)didNotifyRemovalForDevice:(SKTCaptureHelperDevice*) device withResult:(SKTResult) result {
    NSLog(@"didNotifyRemovalForDevice");
    [self updateStatus];
    
    // if that's the softscan scanner
    // then remove its reference and hide
    // the softscan trigger button
    if ( self.softScan == device ) {
        self.softScan = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.triggerButton.hidden = YES;
        });
    }

}

/**
 * called when decoded data are received from a device
 *
 * @param decodedData contains the decoded data
 * @param device identifies the device from which the decoded data comes from
 * @param result contains an error if something wrong happen while getting the decoded data
 * or if the SoftScan trigger operation has been cancelled
 */
-(void)didReceiveDecodedData:(SKTCaptureDecodedData*) decodedData fromDevice:(SKTCaptureHelperDevice*) device withResult:(SKTResult) result {
    if (SKTSUCCESS(result)) {
        // BE CAREFUL THIS CONVERSION FROM NSDATA TO NSSTRING MIGHT NOT WORK WITH
        // THE BARCODES YOUR ARE USING. HERE WE ASSUME THE DECODED DATA ARE UTF8 ENCODED
        dispatch_async(dispatch_get_main_queue(), ^{
            self.decodedDataTextField.text = [NSString stringWithUTF8String:(const char *)[decodedData.DecodedData bytes]];
        });
    }
}

/**
 * called when a error needs to be reported to the application
 *
 * @param error contains the error code
 * @param message contains an optional message, can be null
 */
-(void) didReceiveError:(SKTResult)error withMessage:(NSString *)message{
    self.statusLabel.text=[NSString stringWithFormat:@"Capture is reporting an error: %ld",error];
}

/**
 * called when a device manager is available to the host
 *
 * @param deviceManager identifies the device manager that is just available
 * @param result contains an error if something went wrong during the device connection
 */
-(void)didNotifyArrivalForDeviceManager:(SKTCaptureHelperDeviceManager*) deviceManager withResult:(SKTResult) result{

    self.deviceManager = deviceManager;
    // check if the device manager has a favorite
    // and if yes that means we support the D600
    [deviceManager getFavoriteDevicesWithCompletionHandler:^(SKTResult result, NSString *favorites) {
        if (SKTSUCCESS(result)) {
            if (favorites && favorites.length) {
                self.settings.d600Supported = TRUE;
            }
            NSLog(@"D600 Supported: %d", self.settings.d600Supported);
        } else {
            NSLog(@"getFavoriteDevices returns: %ld", result);
        }
    }];

}
@end
