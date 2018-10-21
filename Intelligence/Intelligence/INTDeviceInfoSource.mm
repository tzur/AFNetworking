// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoSource.h"

#import <AdSupport/AdSupport.h>
#import <LTKit/LTAppIntegrity.h>
#import <LTKit/NSLocale+Language.h>
#import <LTKit/UIDevice+Hardware.h>

#import "INTDeviceInfo.h"
#import "NSLocale+Country.h"
#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTDeviceInfoSource

- (INTDeviceInfo *)deviceInfoWithAppStoreCountry:(nullable NSString *)appStoreCountry
                             usageEventsDisabled:(nullable NSNumber *)usageEventsDisabled {
  auto device = [UIDevice currentDevice];
  auto locale = [NSLocale currentLocale];
  auto infoDict = [[NSBundle mainBundle] infoDictionary];
  auto identifierManager = [ASIdentifierManager sharedManager];
  auto advertisingID = identifierManager.advertisingIdentifier ?: [NSUUID int_zeroUUID];
  auto identifierForVendor = device.identifierForVendor ?: [NSUUID int_zeroUUID];
  BOOL advertisingTrackingEnabled = identifierManager.isAdvertisingTrackingEnabled;
  NSString *appVersion = infoDict[(__bridge NSString *)kCFBundleVersionKey];
  NSString *appVersionShort = infoDict[@"CFBundleShortVersionString"];

  return [[INTDeviceInfo alloc] initWithIdentifierForVendor:identifierForVendor
                                              advertisingID:advertisingID
                                 advertisingTrackingEnabled:advertisingTrackingEnabled
                                                deviceModel:device.lt_platformName
                                                 deviceKind:device.lt_deviceKindString
                                                 iosVersion:device.systemVersion
                                                 appVersion:appVersion
                                            appVersionShort:appVersionShort
                                                   timeZone:[NSTimeZone systemTimeZone].name
                                                    country:locale.int_countryName
                                          preferredLanguage:locale.lt_preferredLanguage
                                         currentAppLanguage:locale.lt_currentAppLanguage
                                            purchaseReceipt:[INTDeviceInfoSource purchaseReceipt]
                                            appStoreCountry:appStoreCountry
                                             inLowPowerMode:@(LTIsJailbroken())
                                                 firmwareID:LTSigningTeamIdentifier()
                                        usageEventsDisabled:usageEventsDisabled];
}

+ (nullable NSData *)purchaseReceipt {
  auto _Nullable receiptURL = [NSBundle mainBundle].appStoreReceiptURL;
  return [NSData dataWithContentsOfURL:receiptURL];
}

@end

NS_ASSUME_NONNULL_END
