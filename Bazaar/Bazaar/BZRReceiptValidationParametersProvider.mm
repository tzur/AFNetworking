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

@end

@implementation BZRReceiptValidationParametersProvider

/// Key to which the App Store locale is written to.
NSString * const kAppStoreLocaleKey = @"appStoreLocale";

@synthesize appStoreLocale = _appStoreLocale;

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
    [self loadAppStoreLocaleFromStorage];
  }

  return self;
}

- (void)loadAppStoreLocaleFromStorage {
  NSString * _Nullable appStoreLocaleIdentifier =
      [self.keychainStorage valueOfClass:NSString.class forKey:kAppStoreLocaleKey
                                   error:nil];

  if (appStoreLocaleIdentifier) {
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
  [self.keychainStorage setValue:[appStoreLocale localeIdentifier] forKey:kAppStoreLocaleKey
                           error:nil];
}

@end

NS_ASSUME_NONNULL_END
