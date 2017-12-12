// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRKeychainStorageMigrator.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Cache used to store the fetched receipt validation status.
@property (readonly, nonatomic) BZRReceiptValidationStatusCache *receiptValidationStatusCache;

/// Object used to provide the current time.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Current application's bundle ID.
@property (readonly, nonatomic) NSString *applicationBundleID;

/// Latest \c BZRReceiptValidationStatus fetched with \c underlyingProvider.
@property (strong, readwrite, nonatomic, nullable)
    BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
@property (strong, readwrite, nonatomic, nullable) NSDate *lastReceiptValidationDate;

/// Subject used to send events;
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
          applicationBundleID:(NSString *)applicationBundleID {
  if (self = [super init]) {
    _receiptValidationStatusCache = receiptValidationStatusCache;
    _timeProvider = timeProvider;
    _underlyingProvider = underlyingProvider;
    _applicationBundleID = applicationBundleID;
    _eventsSubject = [RACSubject subject];
    _eventsSignal = [[RACSignal merge:@[
      self.underlyingProvider.eventsSignal,
      self.eventsSubject
    ]] takeUntil:[self rac_willDeallocSignal]];

    [self loadReceiptValidationStatus];
  }
  return self;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (void)loadReceiptValidationStatus {
  BZRReceiptValidationStatusCacheEntry * _Nullable receiptStatusCacheEntry =
      [self.receiptValidationStatusCache
       loadCacheEntryOfApplicationWithBundleID:self.applicationBundleID error:nil];

  if (receiptStatusCacheEntry) {
    @synchronized (self) {
      self.receiptValidationStatus = receiptStatusCacheEntry.receiptValidationStatus;
      self.lastReceiptValidationDate = receiptStatusCacheEntry.cachingDateTime;
    }
  }
}

- (nullable BZRReceiptValidationStatusCacheEntry *)loadReceiptValidationStatusCacheEntryFromStorage:
    (NSString *)applicationBundleID {
  return [self.receiptValidationStatusCache
      loadCacheEntryOfApplicationWithBundleID:applicationBundleID error:nil];
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (void)storeReceiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus
                     cachingDateTime:(NSDate *)cachingDateTime {
  auto receiptStatusCacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                                  initWithReceiptValidationStatus:receiptValidationStatus
                                  cachingDateTime:cachingDateTime];
  [self.receiptValidationStatusCache storeCacheEntry:receiptStatusCacheEntry
                                 applicationBundleID:self.applicationBundleID error:nil];
  @synchronized (self) {
    self.receiptValidationStatus = receiptStatusCacheEntry.receiptValidationStatus;
    self.lastReceiptValidationDate = receiptStatusCacheEntry.cachingDateTime;
  }
}

#pragma mark -
#pragma mark BZRReceiptValidationStatusProvider
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus {
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

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus:
    (NSString __unused *)applicationBundleID {
  return [self fetchReceiptValidationStatus];
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

#pragma mark -
#pragma mark BZRCachedReceiptValidationStatusProvider+MultiApp
#pragma mark -

@implementation BZRCachedReceiptValidationStatusProvider (MultiApp)

- (RACSignal<BZRMultiAppReceiptValidationStatus *> *)fetchReceiptValidationStatuses:
    (NSSet<NSString *> *)bundledApplicationsIDs {
  @weakify(self);
  return [[[[[bundledApplicationsIDs.rac_sequence.signal
      flattenMap:^(NSString *bundleID) {
        @strongify(self);
        return [self materializedFetchReceiptValidationStatusWithBundleID:bundleID];
      }]
      filter:^BOOL(RACEvent *event) {
        return event.eventType != RACEventTypeCompleted;
      }]
      collect]
      ignore:@[]]
      tryMap:^BZRMultiAppReceiptValidationStatus * _Nullable(NSArray<RACEvent *> *events,
                                                             NSError * __autoreleasing *error) {
        @strongify(self);
        return [self multiAppREceiptValidationStatusFromFetchEvents:events error:error];
      }];
}

- (RACSignal<RACEvent *> *)materializedFetchReceiptValidationStatusWithBundleID:
    (NSString *)applicationBundleID {
  @weakify(self);
  return [[[[[self fetchReceiptValidationStatus:applicationBundleID]
      map:^RACTuple *(BZRReceiptValidationStatus *receiptValidationStatus) {
        return RACTuplePack(applicationBundleID, receiptValidationStatus);
      }]
      catch:^RACSignal *(NSError *error) {
        auto userInfoWithBundleID =
            [error.userInfo mtl_dictionaryByAddingEntriesFromDictionary:
             @{kBZRApplicationBundleIDKey: applicationBundleID}];
        auto errorWithBundleID = [NSError lt_errorWithCode:error.code
                                                  userInfo:userInfoWithBundleID];
        return [RACSignal error:errorWithBundleID];
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self.eventsSubject sendNext:
         [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
      }]
      materialize];
}

- (nullable BZRMultiAppReceiptValidationStatus *)multiAppREceiptValidationStatusFromFetchEvents:
    (NSArray<RACEvent *> *)events error:(NSError * __autoreleasing *)error {
  NSArray<RACTuple *> *tuples = [[events lt_filter:^BOOL(RACEvent *event) {
    return event.eventType == RACEventTypeNext;
  }] lt_map:^RACTuple *(RACEvent *event) {
    return event.value;
  }];

  if (!tuples.count) {
    if (error) {
      NSArray<NSError *> *validationErrors = [events valueForKey:@instanceKeypath(RACEvent, error)];
      *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                        underlyingErrors:validationErrors];
    }
    return nil;
  }

  return [NSDictionary
          dictionaryWithObjects:[tuples valueForKey:@instanceKeypath(RACTuple, second)]
          forKeys:[tuples valueForKey:@instanceKeypath(RACTuple, first)]];
}

- (NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *)
    loadReceiptValidationStatusCacheEntries:(NSSet<NSString *> *)bundledApplicationsIDs {
  return [bundledApplicationsIDs.allObjects lt_reduce:^BZRMultiAppReceiptValidationStatus *
       (BZRMultiAppReceiptValidationStatus *dictionarySoFar, NSString *bundleID) {
         auto _Nullable cacheEntry =
             [self loadReceiptValidationStatusCacheEntryFromStorage:bundleID];
         if (!cacheEntry) {
           return dictionarySoFar;
         }

         return [dictionarySoFar mtl_dictionaryByAddingEntriesFromDictionary:@{
           bundleID: cacheEntry
         }];
       } initial:@{}];
}

@end

NS_ASSUME_NONNULL_END
