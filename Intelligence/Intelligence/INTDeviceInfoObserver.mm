// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoObserver.h"

#import <LTKit/LTKeyValuePersistentStorage.h>

#import "INTDeviceInfo.h"
#import "INTDeviceInfoSource.h"
#import "INTSubscriptionInfo.h"
#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

/// Key in the storage that holds the \c INTDeviceInfo.
static NSString * const kINTStorageDeviceInfoKey = @"DeviceInfo";

/// Key in the storage that holds the \c NSUUID that is the revision ID of the \c INTDeviceInfo in
/// \c kINTStorageDeviceInfoKey.
static NSString * const kINTStorageDeviceInfoRevisionIDKey = @"DeviceInfoRevisionID";

/// Key in the storage that holds the \c NSData that is the device push notification token.
static NSString * const kINTStorageDeviceTokenKey = @"DeviceToken";

/// Key in the storage that holds the \c NSNumber that is the number of times the app had launched
/// on the device.
static NSString * const kINTStorageAppRunCountKey = @"AppRunCount";

/// Key in the storage that holds the \c INTSubscriptionInfo.
static NSString * const kINTSubscriptionInfoKey = @"SubscriptionInfo";

@interface INTDeviceInfoObserver ()

/// Device info source that can create a new \c INTDeviceInfo instance.
@property (readonly, nonatomic) id<INTDeviceInfoSource> deviceInfoSource;

/// Used for storing \c deviceInfo.
@property (readonly, nonatomic) id<LTKeyValuePersistentStorage> storage;

/// Delegate for reporting device info loaded events.
@property (weak, readonly, nonatomic) id<INTDeviceInfoObserverDelegate> delegate;

@end

@implementation INTDeviceInfoObserver

- (instancetype)initWithDelegate:(id<INTDeviceInfoObserverDelegate>)delegate {
  return [self initWithDeviceInfoSource:[[INTDeviceInfoSource alloc] init]
                                storage:[NSUserDefaults standardUserDefaults] delegate:delegate];
}

- (instancetype)initWithDeviceInfoSource:(id<INTDeviceInfoSource>)deviceInfoSource
                                 storage:(id<LTKeyValuePersistentStorage>)storage
                                delegate:(id<INTDeviceInfoObserverDelegate>)delegate {
  if (self = [super init]) {
    @synchronized (self) {
      _deviceInfoSource = deviceInfoSource;
      _storage = storage;
      _delegate = delegate;
      [self updateRunCount];
      [self updateDeviceInfoIfNeededWithAppStoreCountry:nil];
    }
  }
  return self;
}

- (void)updateRunCount {
  NSNumber *runCount = [self loadStoredObjectForKey:kINTStorageAppRunCountKey type:NSNumber.class]
      ?: @0;
  runCount = @([runCount integerValue] + 1);

  [self.storage setObject:runCount forKey:kINTStorageAppRunCountKey];
  [self.delegate appRunCountUpdated:runCount];
}

- (void)updateDeviceInfoIfNeededWithAppStoreCountry:(nullable NSString *)appStoreCountry {
  auto _Nullable storedDeviceInfo = [self loadStoredDeviceInfo];
  appStoreCountry = appStoreCountry ?: storedDeviceInfo.appStoreCountry;
  auto deviceInfo = [self.deviceInfoSource deviceInfoWithAppStoreCountry:appStoreCountry];

  if ([deviceInfo.identifierForVendor isEqual:[NSUUID int_zeroUUID]]) {
    deviceInfo = [deviceInfo
                  deviceInfoWithIdentifierForVendor:storedDeviceInfo.identifierForVendor];
  }

  auto _Nullable deviceInfoRevisionID = [self loadStoredDeviceInfoRevisionID];

  if ([deviceInfo isEqual:storedDeviceInfo] && deviceInfoRevisionID) {
    [self.delegate deviceInfoObserver:self loadedDeviceInfo:deviceInfo
                 deviceInfoRevisionID:deviceInfoRevisionID isNewRevision:NO];
    return;
  }

  deviceInfoRevisionID = [NSUUID UUID];
  [self.delegate deviceInfoObserver:self loadedDeviceInfo:deviceInfo
               deviceInfoRevisionID:deviceInfoRevisionID isNewRevision:YES];
  [self storeDeviceInfo:deviceInfo revisionID:deviceInfoRevisionID];
}

- (nullable INTDeviceInfo *)loadStoredDeviceInfo {
  return [self loadArchivedObjectForKey:kINTStorageDeviceInfoKey class:INTDeviceInfo.class];
}

- (nullable id)loadArchivedObjectForKey:(NSString *)key class:(Class)expectedClass {
  NSData * _Nullable cachedData = [self loadStoredObjectForKey:key type:NSData.class];
  if (!cachedData) {
    return nil;
  }

  NSError *error;
  id _Nullable result =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:cachedData error:&error];
  if (!result) {
    LogError(@"Failed to load model from key %@, error: %@", key, error);
    return nil;
  }

  if (![result isKindOfClass:expectedClass]) {
    LogError(@"Expected cached model to be of type: %@, got: %@", expectedClass, [result class]);
    return nil;
  }

  return result;
}

- (nullable id)loadStoredObjectForKey:(NSString *)key type:(Class)type {
  id _Nullable cachedObject = [self.storage objectForKey:key];
  if (!cachedObject) {
    return nil;
  }

  if (![cachedObject isKindOfClass:type]) {
    LogError(@"Expected cached archive for key: %@ to be of type: %@, got: %@", key, type,
             [cachedObject class]);
    return nil;
  }

  return cachedObject;
}

- (nullable NSUUID *)loadStoredDeviceInfoRevisionID {
  NSString * _Nullable cachedUUIDString =
      [self loadStoredObjectForKey:kINTStorageDeviceInfoRevisionIDKey type:NSString.class];

  return cachedUUIDString ? [[NSUUID alloc] initWithUUIDString:cachedUUIDString] : nil;
}

- (void)setAppStoreCountry:(NSString *)appStoreCountry {
  @synchronized (self) {
    [self updateDeviceInfoIfNeededWithAppStoreCountry:appStoreCountry];
  }
}

- (void)setDeviceToken:(nullable NSData *)deviceToken {
  @synchronized (self) {
    NSData * _Nullable storedDeviceToken =
        [self loadStoredObjectForKey:kINTStorageDeviceTokenKey type:NSData.class];
    if (storedDeviceToken == deviceToken || [storedDeviceToken isEqual:deviceToken]) {
      return;
    }

    [self.delegate deviceTokenDidChange:deviceToken];
    [self.storage setObject:deviceToken forKey:kINTStorageDeviceTokenKey];
  }
}

- (void)storeDeviceInfo:(INTDeviceInfo *)deviceInfo revisionID:(NSUUID *)revisionID {
  [self.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:deviceInfo]
                   forKey:kINTStorageDeviceInfoKey];
  [self.storage setObject:revisionID.UUIDString forKey:kINTStorageDeviceInfoRevisionIDKey];
}

- (void)setSubscriptionInfo:(nullable INTSubscriptionInfo *)subscriptionInfo {
  @synchronized (self) {
    auto _Nullable storedSubscriptionInfo = [self loadStoredSubscriptionInfo];
    if (storedSubscriptionInfo == subscriptionInfo ||
        [storedSubscriptionInfo isEqual:subscriptionInfo]) {
      return;
    }

    [self.delegate subscriptionInfoDidChanged:subscriptionInfo];

    auto _Nullable dataToStore = subscriptionInfo ?
        [NSKeyedArchiver archivedDataWithRootObject:subscriptionInfo] : nil;
    [self.storage setObject:dataToStore forKey:kINTSubscriptionInfoKey];
  }
}

- (nullable INTSubscriptionInfo *)loadStoredSubscriptionInfo {
  return [self loadArchivedObjectForKey:kINTSubscriptionInfoKey class:INTSubscriptionInfo.class];
}

@end

NS_ASSUME_NONNULL_END
