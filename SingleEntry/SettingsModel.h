//
//  SettingsModel.h
//  SingleEntry
//
//  Copyright © 2018 Socket Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

// defines the setting model that can be
// edited in the Settings view
@interface SettingsModel : NSObject
@property (nonatomic) BOOL softScanEnabled;
@property (nonatomic) BOOL NFCSupported;
@end

