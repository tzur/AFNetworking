// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRKeychainStorageMigrator.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Cache used to store the fetched receipt validation status.
@property (readonly, nonatomic) BZRReceiptValidationStatusCache *receiptValidationStatusCache;

/// Object used to provide the current time.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject *eventsSubject;

/// Latest \c BZRReceiptValidationStatus fetched with \c underlyingProvider.
@property (strong, readwrite, nonatomic, nullable)
    BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
@property (strong, readwrite, nonatomic, nullable) NSDate *lastReceiptValidationDate;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider {
  if (self = [super init]) {
    _receiptValidationStatusCache = receiptValidationStatusCache;
    _timeProvider = timeProvider;
    _underlyingProvider = underlyingProvider;
    _eventsSubject = [RACSubject subject];
    _eventsSignal = [[RACSignal merge:@[
      [self.eventsSubject replayLast],
      self.underlyingProvider.eventsSignal
    ]]
    takeUntil:[self rac_willDeallocSignal]];

    [self loadReceiptValidationStatus];
  }
  return self;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (void)loadReceiptValidationStatus {
  NSError *underlyingError;
  BZRReceiptValidationStatusCacheEntry * _Nullable receiptStatusCacheEntry =
      [self.receiptValidationStatusCache loadCacheEntry:&underlyingError];

  if (!receiptStatusCacheEntry && underlyingError) {
    [self.eventsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:underlyingError]];
  } else {
    @synchronized (self) {
      self.receiptValidationStatus = receiptStatusCacheEntry.receiptValidationStatus;
      self.lastReceiptValidationDate = receiptStatusCacheEntry.cachingDateTime;
    }
  }
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (void)storeReceiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus
                     cachingDateTime:(NSDate *)cachingDateTime {
  auto receiptStatusCacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                                  initWithReceiptValidationStatus:receiptValidationStatus
                                  cachingDateTime:cachingDateTime];
  NSError *error;
  BOOL success =
      [self.receiptValidationStatusCache storeCacheEntry:receiptStatusCacheEntry error:&error];
  if (!success && error) {
    [self.eventsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
  }
  @synchronized (self) {
    self.receiptValidationStatus = receiptStatusCacheEntry.receiptValidationStatus;
    self.lastReceiptValidationDate = receiptStatusCacheEntry.cachingDateTime;
  }
}

#pragma mark -
#pragma mark BZRReceiptValidationStatusProvider
#pragma mark -

- (RACSignal *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[self.underlyingProvider fetchReceiptValidationStatus]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
       @strongify(self);
       [[self.timeProvider currentTime] subscribeNext:^(NSDate *currentTime) {
         @strongify(self);
         [self storeReceiptValidationStatus:receiptValidationStatus cachingDateTime:currentTime];
       }];
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

  auto isExpiredKeypath = @keypath(self.receiptValidationStatus, receipt.subscription.isExpired);
  auto receiptValidationStatus =
      [self.receiptValidationStatus modelByOverridingPropertyAtKeypath:isExpiredKeypath
                                                             withValue:@YES];

  [self storeReceiptValidationStatus:receiptValidationStatus
                     cachingDateTime:self.lastReceiptValidationDate];
}

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  @synchronized (self) {
    return _receiptValidationStatus;
  }
}

- (nullable NSDate *)lastReceiptValidationDate {
  @synchronized (self) {
    return _lastReceiptValidationDate;
  }
}

@end

NS_ASSUME_NONNULL_END
