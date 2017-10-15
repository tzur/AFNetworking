// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoObserver.h"

#import "INTDeviceInfo.h"
#import "INTDeviceInfoSource.h"
#import "INTStorage.h"
#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

/// Conform \c NSUserDefaults to \c INTStorage to be used as the default storage for storing device
/// info.
@interface NSUserDefaults (Storage) <INTStorage>
@end

/// Key in the storage that holds the \c INTDeviceInfo.
static NSString * const kINTStorageDeviceInfoKey = @"DeviceInfo";

/// Key in the storage that holds the \c NSUUID that is the revision ID of the \c INTDeviceInfo in
/// \c kINTStorageDeviceInfoKey.
static NSString * const kINTStorageDeviceInfoRevisionIDKey = @"DeviceInfoRevisionID";

/// Key in the storage that holds the \c NSData that is the device push notification token.
static NSString * const kINTStorageDeviceTokenKey = @"DeviceToken";

/// Key in the storage that holds the \c NSNumber that is the number of times the app had launched
/// on the device.
static NSString * const kINTStorageAppRunCount = @"AppRunCount";

@interface INTDeviceInfoObserver ()

/// Device info source that can create a new \c INTDeviceInfo instance.
@property (readonly, nonatomic) id<INTDeviceInfoSource> deviceInfoSource;

/// Used for storing \c deviceInfo.
@property (readonly, nonatomic) id<INTStorage> storage;

/// Delegate for reporting device info loaded events.
@property (weak, readonly, nonatomic) id<INTDeviceInfoObserverDelegate> delegate;

@end

@implementation INTDeviceInfoObserver

- (instancetype)initWithDelegate:(id<INTDeviceInfoObserverDelegate>)delegate {
  return [self initWithDeviceInfoSource:[[INTDeviceInfoSource alloc] init]
                                storage:[NSUserDefaults standardUserDefaults] delegate:delegate];
}

- (instancetype)initWithDeviceInfoSource:(id<INTDeviceInfoSource>)deviceInfoSource
                                 storage:(id<INTStorage>)storage
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
  NSNumber *runCount = [self loadStoredObjectForKey:kINTStorageAppRunCount type:NSNumber.class]
      ?: @0;
  runCount = @([runCount integerValue] + 1);

  [self.storage setObject:runCount forKey:kINTStorageAppRunCount];
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
  NSData * _Nullable cachedData = [self loadStoredObjectForKey:kINTStorageDeviceInfoKey
                                                          type:NSData.class];
  if (!cachedData) {
    return nil;
  }

  NSError *error;
  INTDeviceInfo * _Nullable result =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:cachedData error:&error];
  if (!result) {
    LogError(@"Failed to load model from key %@, error: %@", kINTStorageDeviceInfoKey, error);
    return nil;
  }

  if (![result isKindOfClass:INTDeviceInfo.class]) {
    LogError(@"Expected cached model to be of type: %@, got: %@", INTDeviceInfo.class,
             [result class]);
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

@end

NS_ASSUME_NONNULL_END
