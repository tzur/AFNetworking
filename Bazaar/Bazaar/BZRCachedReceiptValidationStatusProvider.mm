// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Storage used to cache the latest fetched \c receiptValidationStatus.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Latest \c BZRReceiptValidationStatus fetched with \c underlyingProvider.
@property (strong, readwrite, nonatomic, nullable) BZRReceiptValidationStatus *
    receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
@property (strong, readwrite, nonatomic) NSDate *lastReceiptValidationDate;

/// Sends storage errors as values. The subject completes when the receiver is deallocated. The
/// subject doesn't err.
@property (readonly, nonatomic) RACSubject *nonCriticalErrorsSubject;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize nonCriticalErrorsSignal = _nonCriticalErrorsSignal;
@synthesize receiptValidationStatus = _receiptValidationStatus;
@synthesize lastReceiptValidationDate = _lastReceiptValidationDate;

/// Key to the \c receiptValidationStatus stored in the secure storage.
NSString * const kValidationStatusStorageKey = @"validationStatus";

/// Key for secure storage of the date of the last receipt validation.
NSString * const kLastReceiptValidationDateKey = @"lastReceiptValidationDate";

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
    _nonCriticalErrorsSubject = [RACSubject subject];
    _nonCriticalErrorsSignal = [[RACSignal merge:@[
      self.nonCriticalErrorsSubject,
      self.underlyingProvider.nonCriticalErrorsSignal
    ]]
    takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

#pragma mark -
#pragma mark Loading/storing receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  if (!_receiptValidationStatus) {
    _receiptValidationStatus = [self loadValueOfClass:[BZRReceiptValidationStatus class]
                                               forKey:kValidationStatusStorageKey];
  }
  return _receiptValidationStatus;
}

- (void)setReceiptValidationStatus:(nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  _receiptValidationStatus = receiptValidationStatus;
  BOOL success = [self storeValue:receiptValidationStatus forKey:kValidationStatusStorageKey];
  if (success) {
    [self storeLastReceiptValidationDate];
  }
}

- (void)storeLastReceiptValidationDate {
  @weakify(self);
  [[self.timeProvider currentTime] subscribeNext:^(NSDate *currentTime) {
    @strongify(self);
    self.lastReceiptValidationDate = currentTime;
    [self storeValue:self.lastReceiptValidationDate forKey:kLastReceiptValidationDateKey];
  } error:^(NSError *error) {
    @strongify(self);
    [self.nonCriticalErrorsSubject sendNext:error];
  }];
}

#pragma mark -
#pragma mark Getting last validation date
#pragma mark -

- (nullable NSDate *)lastReceiptValidationDate {
  if (!_lastReceiptValidationDate && self.receiptValidationStatus) {
    _lastReceiptValidationDate =
        [self loadValueOfClass:[NSDate class] forKey:kLastReceiptValidationDateKey];
  }
  return _lastReceiptValidationDate;
}

#pragma mark -
#pragma mark Loading/store values
#pragma mark -

- (nullable id)loadValueOfClass:(Class)valueClass forKey:(NSString *)key {
  NSError *error;
  id value = [self.keychainStorage valueOfClass:valueClass forKey:key error:&error];
  if (error) {
    [self.nonCriticalErrorsSubject sendNext:error];
    return nil;
  }
  return value;
}


- (BOOL)storeValue:(id)value forKey:(NSString *)key {
  NSError *error;
  BOOL success = [self.keychainStorage setValue:value forKey:key error:&error];
  if (!success) {
    [self.nonCriticalErrorsSubject sendNext:
     [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed underlyingError:error]];
  }

  return success;
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
