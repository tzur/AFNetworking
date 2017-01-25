// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Storage used to cache the latest fetched \c receiptValidationStatus.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Object used to provide the current time.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Latest \c BZRReceiptValidationStatus fetched with \c underlyingProvider.
@property (strong, readwrite, nonatomic, nullable) BZRReceiptValidationStatus *
    receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
@property (strong, readwrite, nonatomic, nullable) NSDate *lastReceiptValidationDate;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject *eventsSubject;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize receiptValidationStatus = _receiptValidationStatus;
@synthesize lastReceiptValidationDate = _lastReceiptValidationDate;

/// Storage key to which the cached receipt validation status is stored to. Cached status is stored
/// as an \c NSDictionary containing both the receipt validation status and the last receipt
/// validation date.
NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

/// Key to a \c BZRReceiptValidationStatus in the cached receipt validation status.
NSString * const kValidationStatusKey = @"validationStatus";

/// Key to an \c NSDate in the cached receipt validation status specifying the time and date of the
/// cached receipt validation status.
NSString * const kValidationDateKey = @"validationDate";

/// Key to the \c receiptValidationStatus stored in the secure storage used in previous versions.
NSString * const kOldVersionValidationStatusStorageKey = @"validationStatus";

/// Key for secure storage of the date of the last receipt validation used in previous versions.
NSString * const kOldVersionValidationDateStorageKey = @"lastReceiptValidationDate";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
                           timeProvider:(id<BZRTimeProvider>)timeProvider
                     underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
    _timeProvider = timeProvider;
    _underlyingProvider = underlyingProvider;
    _eventsSubject = [RACSubject subject];
    [self refreshReceiptValidationStatus:nil];
  }
  return self;
}

#pragma mark -
#pragma mark Sending events
#pragma mark -

- (RACSignal *)eventsSignal {
  return [[RACSignal merge:@[
    self.eventsSubject,
    self.underlyingProvider.eventsSignal
  ]]
  takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (void)setReceiptValidationStatus:(nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  @synchronized (self) {
    _receiptValidationStatus = receiptValidationStatus;
    [self storeReceiptValidationStatus:receiptValidationStatus];
  }
}

- (void)storeReceiptValidationStatus:
    (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  if (!receiptValidationStatus) {
    [self storeValue:nil forKey:kCachedReceiptValidationStatusStorageKey];
    return;
  }

  [[[[self.timeProvider currentTime]
    doNext:^(NSDate *currentTime) {
       @synchronized (self) {
         self.lastReceiptValidationDate = currentTime;
       }
    }]
    map:^NSDictionary<NSString *, id> *(NSDate *currentTime) {
      return @{
        kValidationStatusKey: receiptValidationStatus,
        kValidationDateKey: currentTime
      };
    }]
    subscribeNext:^(NSDictionary<NSString *, id> *receiptValidationStatusForCaching) {
     [self storeValue:receiptValidationStatusForCaching
               forKey:kCachedReceiptValidationStatusStorageKey];
    } error:^(NSError *error) {
     [self.eventsSubject sendNext:
      [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
    }];
}

- (BOOL)storeValue:(nullable id)value forKey:(NSString *)key {
  NSError *storageError;
  BOOL success = [self.keychainStorage setValue:value forKey:key error:&storageError];
  if (!success) {
    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed
                               underlyingError:storageError];
    [self.eventsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
  }

  return success;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatus *)refreshReceiptValidationStatus:
    (NSError * __autoreleasing *)error {
  @synchronized (self) {
    NSError *underlyingError;
    NSDictionary<NSString *, id> *cachedReceiptValidationStatus =
        [self loadValueOfClass:[NSDictionary class]
                        forKey:kCachedReceiptValidationStatusStorageKey
                         error:&underlyingError];
    if (!cachedReceiptValidationStatus && !underlyingError) {
      cachedReceiptValidationStatus =
          [self loadOldVersionCachedValidationStatusFormat:&underlyingError];
    }

    if (underlyingError) {
      if (error) {
        *error = underlyingError;
      }
      return nil;
    } 

    [self willChangeValueForKey:@keypath(self, receiptValidationStatus)];
    _receiptValidationStatus = cachedReceiptValidationStatus[kValidationStatusKey];
    [self didChangeValueForKey:@keypath(self, receiptValidationStatus)];
    self.lastReceiptValidationDate = cachedReceiptValidationStatus[kValidationDateKey];

    return self.receiptValidationStatus;
  }
}

- (nullable NSDictionary<NSString *, id> *)loadOldVersionCachedValidationStatusFormat:
    (NSError * __autoreleasing *)error {
  BZRReceiptValidationStatus *validationStatus =
      [self loadValueOfClass:[BZRReceiptValidationStatus class]
                      forKey:kOldVersionValidationStatusStorageKey
                       error:error];
  if (!validationStatus) {
    return nil;
  }
  
  NSDate *validationDate = [self loadValueOfClass:[NSDate class]
                                           forKey:kOldVersionValidationDateStorageKey
                                            error:error];
  if (!validationDate) {
    return nil;
  }

  return @{
    kValidationStatusKey: validationStatus,
    kValidationDateKey: validationDate
  };
}

- (nullable id)loadValueOfClass:(Class)valueClass forKey:(NSString *)key
                          error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  id value = [self.keychainStorage valueOfClass:valueClass forKey:key error:&underlyingError];
  if (underlyingError) {
    [self.eventsSubject sendNext:
        [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:underlyingError]];

    if (error) {
      *error = underlyingError;
    }
  }
  return value;
}

#pragma mark -
#pragma mark Fetching receipt validation status
#pragma mark -

- (RACSignal *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[self.underlyingProvider fetchReceiptValidationStatus]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        self.receiptValidationStatus = receiptValidationStatus;
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

#pragma mark -
#pragma mark Expiring subscription
#pragma mark -

- (void)expireSubscription {
  if (!self.receiptValidationStatus.receipt.subscription) {
    return;
  }

  BZRReceiptInfo *receipt = self.receiptValidationStatus.receipt;
  BZRReceiptSubscriptionInfo *subscription =
      [receipt.subscription modelByOverridingProperty:@keypath(receipt.subscription, isExpired)
                                            withValue:@YES];
  receipt =
      [receipt modelByOverridingProperty:@keypath(receipt, subscription) withValue:subscription];
  self.receiptValidationStatus = [self.receiptValidationStatus
      modelByOverridingProperty:@keypath(self.receiptValidationStatus, receipt) withValue:receipt];
}

@end

NS_ASSUME_NONNULL_END
