// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptValidationParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationParametersProvider ()

/// Keychain storage used to save App Store locale.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Subject used to send storage error events.
@property (readonly, nonatomic) RACSubject *eventsSubject;

@end

@implementation BZRReceiptValidationParametersProvider

/// Key to which the App Store locale is written to.
NSString * const kAppStoreLocaleKey = @"appStoreLocale";

@synthesize appStoreLocale = _appStoreLocale;
@synthesize eventsSignal = _eventsSignal;

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
    _eventsSubject = [RACSubject subject];
    _eventsSignal = [[self.eventsSubject replayLast] takeUntil:[self rac_willDeallocSignal]];

    [self loadAppStoreLocaleFromStorage];
  }

  return self;
}

- (void)loadAppStoreLocaleFromStorage {
  NSError *error;
  NSError *storageError;

  NSString * _Nullable appStoreLocaleIdentifier =
      [self.keychainStorage valueOfClass:NSString.class forKey:kAppStoreLocaleKey
                                   error:&storageError];

  if (!appStoreLocaleIdentifier && storageError) {
    auto description =
        [NSString stringWithFormat:@"Failed to load the value for key: %@", kAppStoreLocaleKey];
    error = [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed
                      underlyingError:storageError description:@"%@", description];
    [self.eventsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
  } else {
    @synchronized(self) {
      [self willChangeValueForKey:@keypath(self, appStoreLocale)];
      _appStoreLocale = [NSLocale localeWithLocaleIdentifier:appStoreLocaleIdentifier];
      [self didChangeValueForKey:@keypath(self, appStoreLocale)];
    }
  }
}

- (nullable BZRReceiptValidationParameters *)receiptValidationParameters {
  return [BZRReceiptValidationParameters defaultParametersWithLocale:self.appStoreLocale];
}

- (nullable NSLocale *)appStoreLocale {
  @synchronized(self) {
    return _appStoreLocale;
  }
}

- (void)setAppStoreLocale:(nullable NSLocale *)appStoreLocale {
  @synchronized(self) {
    if (appStoreLocale == _appStoreLocale || [appStoreLocale isEqual:_appStoreLocale]) {
      return;
    }

    _appStoreLocale = appStoreLocale;
    [self storeAppStoreLocaleToStorage:appStoreLocale];
  }
}

- (void)storeAppStoreLocaleToStorage:(nullable NSLocale *)appStoreLocale {
  NSError *error;
  NSError *storageError;

  BOOL success =
      [self.keychainStorage setValue:[appStoreLocale localeIdentifier] forKey:kAppStoreLocaleKey
                               error:&storageError];

  if (!success && storageError) {
    auto description =
        [NSString stringWithFormat:@"Failed to store the value: %@ for key: %@", appStoreLocale,
         kAppStoreLocaleKey];
    error = [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed
                      underlyingError:storageError description:@"%@", description];
    [self.eventsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
  }
}

@end

NS_ASSUME_NONNULL_END
