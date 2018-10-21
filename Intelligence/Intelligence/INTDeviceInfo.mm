// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTDeviceInfo

- (instancetype)initWithIdentifierForVendor:(NSUUID *)identifierForVendor
                              advertisingID:(NSUUID *)advertisingID
                 advertisingTrackingEnabled:(BOOL)advertisingTrackingEnabled
                                deviceModel:(NSString *)deviceModel
                                 deviceKind:(NSString *)deviceKind
                                 iosVersion:(NSString *)iosVersion appVersion:(NSString *)appVersion
                            appVersionShort:(NSString *)appVersionShort
                                   timeZone:(NSString *)timeZone
                                    country:(nullable NSString *)country
                          preferredLanguage:(nullable NSString *)preferredLanguage
                         currentAppLanguage:(nullable NSString *)currentAppLanguage
                            purchaseReceipt:(nullable NSData *)purchaseReceipt
                            appStoreCountry:(nullable NSString *)appStoreCountry
                             inLowPowerMode:(nullable NSNumber *)inLowPowerMode
                                 firmwareID:(nullable NSString *)firmwareID
                        usageEventsDisabled:(nullable NSNumber *)usageEventsDisabled {
  if (self = [super init]) {
    _identifierForVendor = identifierForVendor;
    _advertisingID = advertisingID;
    _advertisingTrackingEnabled = advertisingTrackingEnabled;
    _deviceModel = deviceModel;
    _deviceKind = deviceKind;
    _iosVersion = iosVersion;
    _appVersion = appVersion;
    _appVersionShort = appVersionShort;
    _timeZone = timeZone;
    _country = country;
    _preferredLanguage = preferredLanguage;
    _currentAppLanguage = currentAppLanguage;
    _purchaseReceipt = purchaseReceipt;
    _appStoreCountry = appStoreCountry;
    _inLowPowerMode = inLowPowerMode;
    _firmwareID = firmwareID;
    _usageEventsDisabled = usageEventsDisabled;
  }

  return self;
}

- (instancetype)deviceInfoWithIdentifierForVendor:(NSUUID *)identifierForVendor {
  return [[INTDeviceInfo alloc] initWithIdentifierForVendor:identifierForVendor
                                              advertisingID:self.advertisingID
                                 advertisingTrackingEnabled:self.advertisingTrackingEnabled
                                                deviceModel:self.deviceModel
                                                 deviceKind:self.deviceKind
                                                 iosVersion:self.iosVersion
                                                 appVersion:self.appVersion
                                            appVersionShort:self.appVersionShort
                                                   timeZone:self.timeZone
                                                    country:self.country
                                          preferredLanguage:self.preferredLanguage
                                         currentAppLanguage:self.currentAppLanguage
                                            purchaseReceipt:self.purchaseReceipt
                                            appStoreCountry:self.appStoreCountry
                                             inLowPowerMode:self.inLowPowerMode
                                                 firmwareID:self.firmwareID
                                        usageEventsDisabled:self.usageEventsDisabled];
}

@end

NS_ASSUME_NONNULL_END
