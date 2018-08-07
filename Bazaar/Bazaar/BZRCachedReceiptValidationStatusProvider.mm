// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Object used to provide the current time.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Seconds until the cache is invalidated, starting from the date of the last validation.
@property (readonly, nonatomic) NSTimeInterval cachedEntryTimeToLive;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider {
  return [self initWithCache:receiptValidationStatusCache timeProvider:timeProvider
          underlyingProvider:underlyingProvider cachedEntryDaysToLive:14];
}

- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
        cachedEntryDaysToLive:(NSUInteger)cachedEntryDaysToLive {
  if (self = [super init]) {
    _cache = receiptValidationStatusCache;
    _timeProvider = timeProvider;
    _underlyingProvider = underlyingProvider;
    _cachedEntryTimeToLive = [BZRTimeConversion numberOfSecondsInDays:cachedEntryDaysToLive];
    _eventsSubject = [RACSubject subject];
    _eventsSignal = [[RACSignal merge:@[
      self.underlyingProvider.eventsSignal,
      self.eventsSubject
    ]] takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatusCacheEntry *)loadReceiptValidationStatusCacheEntryFromStorage:
    (NSString *)applicationBundleID {
  return [self.cache loadCacheEntryOfApplicationWithBundleID:applicationBundleID error:nil];
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (void)storeReceiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus
                     cachingDateTime:(NSDate *)cachingDateTime
                 applicationBundleID:(NSString *)applicationBundleID {
  auto receiptStatusCacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                                  initWithReceiptValidationStatus:receiptValidationStatus
                                  cachingDateTime:cachingDateTime];
  [self.cache storeCacheEntry:receiptStatusCacheEntry
          applicationBundleID:applicationBundleID error:nil];
}

#pragma mark -
#pragma mark BZRReceiptValidationStatusProvider
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus:
    (NSString *)applicationBundleID {
  @weakify(self);
  return [[[[self.underlyingProvider fetchReceiptValidationStatus:applicationBundleID]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        if (!self) {
          return;
        }

        [self rac_liftSelector:
            @selector(storeReceiptValidationStatus:cachingDateTime:applicationBundleID:)
            withSignalsFromArray:@[
              [RACSignal return:receiptValidationStatus],
              [self.timeProvider currentTime],
              [RACSignal return:applicationBundleID]
            ]];
      }]
      doError:^(NSError *) {
        @strongify(self);
        [self invalidateReceiptValidationStatusIfNeeded:applicationBundleID];
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

- (void)invalidateReceiptValidationStatusIfNeeded:(NSString *)applicationBundleID {
  auto _Nullable cacheEntry =
      [self.cache loadCacheEntryOfApplicationWithBundleID:applicationBundleID error:nil];
  auto _Nullable subscription = cacheEntry.receiptValidationStatus.receipt.subscription;

  if (!subscription || subscription.isExpired) {
    return;
  }

  @weakify(self);
  [[[self.timeProvider currentTime]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(NSDate *currentTime) {
        @strongify(self);
        if ([currentTime timeIntervalSinceDate:cacheEntry.cachingDateTime] -
            self.cachedEntryTimeToLive < 0) {
          return;
        }

        [self invalidateCachedEntry:cacheEntry currentTime:currentTime
                applicationBundleID:applicationBundleID];
      }];
}

- (void)invalidateCachedEntry:(BZRReceiptValidationStatusCacheEntry *)cacheEntry
                  currentTime:(NSDate *)currentTime
          applicationBundleID:(NSString *)applicationBundleID {
  auto receiptValidationStatusWithExpiredSubscription = [cacheEntry.receiptValidationStatus
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptValidationStatus,
      receipt.subscription.isExpired) withValue:@YES];
  [self storeReceiptValidationStatus:receiptValidationStatusWithExpiredSubscription
                     cachingDateTime:currentTime applicationBundleID:applicationBundleID];
}

- (void)revertPrematureInvalidationOfReceiptValidationStatus:(NSString *)applicationBundleID {
  auto _Nullable cacheEntry =
      [self loadReceiptValidationStatusCacheEntryFromStorage:applicationBundleID];
  if (!cacheEntry) {
    return;
  }

  if ([self wasSubscriptionInvalidatedPrematurely:cacheEntry]) {
    auto receiptValidationStatus = nn(cacheEntry).receiptValidationStatus;
    receiptValidationStatus = [receiptValidationStatus modelByOverridingPropertyAtKeypath:
                               @keypath(receiptValidationStatus, receipt.subscription.isExpired)
                               withValue:@NO];
    [self storeReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:cacheEntry.cachingDateTime
                   applicationBundleID:applicationBundleID];
  }
}

- (BOOL)wasSubscriptionInvalidatedPrematurely:
    (BZRReceiptValidationStatusCacheEntry *)cacheEntry {
  auto subscription = cacheEntry.receiptValidationStatus.receipt.subscription;
  BOOL receiptWasValidatedBeforeSubscriptionExpiration =
      [subscription.expirationDateTime
       compare:cacheEntry.receiptValidationStatus.validationDateTime] == NSOrderedDescending;
  BOOL timeToLiveHasNotPassed = [[NSDate date] timeIntervalSinceDate:cacheEntry.cachingDateTime] -
      self.cachedEntryTimeToLive < 0;
  return subscription.isExpired && !subscription.cancellationDateTime &&
      receiptWasValidatedBeforeSubscriptionExpiration && timeToLiveHasNotPassed;
}

@end

#pragma mark -
#pragma mark BZRCachedReceiptValidationStatusProvider+MultiApp
#pragma mark -

@implementation BZRCachedReceiptValidationStatusProvider (MultiApp)

- (RACSignal<BZRMultiAppReceiptValidationStatus *> *)fetchReceiptValidationStatuses:
    (NSSet<NSString *> *)bundledApplicationsIDs {
  @weakify(self);
  return [[[[[bundledApplicationsIDs.rac_sequence.signal
      takeUntil:self.rac_willDeallocSignal]
      flattenMap:^(NSString *bundleID) {
        @strongify(self);
        return [self fetchReceiptValidationStatusWithBundleID:bundleID];
      }]
      collect]
      ignore:@[]]
      tryMap:^BZRMultiAppReceiptValidationStatus * _Nullable(NSArray<RACTuple *> *events,
                                                             NSError * __autoreleasing *error) {
        @strongify(self);
        if (!self) {
          return @{};
        }

        return [self multiAppReceiptValidationStatusFromTuples:events error:error];
      }];
}

- (RACSignal<RACEvent *> *)fetchReceiptValidationStatusWithBundleID:
    (NSString *)applicationBundleID {
  @weakify(self);
  return [[[[self fetchReceiptValidationStatus:applicationBundleID]
      map:^RACTuple *(BZRReceiptValidationStatus *receiptValidationStatus) {
        return RACTuplePack(applicationBundleID, receiptValidationStatus);
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self.eventsSubject sendNext:
         [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
      }]
      catch:^RACSignal *(NSError *error) {
        @strongify(self);
        auto _Nullable cacheEntry =
            [self loadReceiptValidationStatusCacheEntryFromStorage:applicationBundleID];
        return [RACSignal return:
                RACTuplePack(applicationBundleID, cacheEntry.receiptValidationStatus, error)];
      }];
}

- (nullable BZRMultiAppReceiptValidationStatus *)multiAppReceiptValidationStatusFromTuples:
    (NSArray<RACTuple *> *)tuples error:(NSError * __autoreleasing *)error {
  if ([self didAllValidationsFail:tuples]) {
    if (error) {
      NSArray<NSError *> *validationErrors = [tuples valueForKey:@instanceKeypath(RACTuple, third)];
      *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                        underlyingErrors:validationErrors];
    }
    return nil;
  }

  // This array contains at least one element, otherwise it means that all the validations failed
  // and \c nil was returned in the condition above.
  auto tuplesWithValidReceiptValidationStatus =
      [tuples lt_filter:^BOOL(RACTuple *tuple) {
        return tuple.second != nil;
      }];

  return [NSDictionary dictionaryWithObjects:[tuplesWithValidReceiptValidationStatus
                                              valueForKey:@instanceKeypath(RACTuple, second)]
                                     forKeys:[tuplesWithValidReceiptValidationStatus
                                              valueForKey:@instanceKeypath(RACTuple, first)]];
}

- (BOOL)didAllValidationsFail:(NSArray<RACTuple *> *)tuples {
  return [tuples lt_filter:^BOOL(RACTuple *tuple) {
    return tuple.third != nil;
  }].count == tuples.count;
}

@end

NS_ASSUME_NONNULL_END
