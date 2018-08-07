// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationDateProvider.h"

#import "BZRFakeAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"

// Stubs \c receiptValidationStatusProvider to return the given \c bundleIDToCacheEntries.
static void BZRStubLoadedCacheEntries(
  BZRReceiptValidationStatusCache *receiptValidationStatusCache,
  NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *bundleIDToCacheEntries) {
  OCMStub([receiptValidationStatusCache
      loadReceiptValidationStatusCacheEntries:OCMOCK_ANY]).andReturn(bundleIDToCacheEntries);
}

// Returns a \c BZRReceiptValidationStatusCacheEntry that contains the given
// \c lastReceiptValidationDate and a receipt validation status with non-expired subscription.
static BZRReceiptValidationStatusCacheEntry *BZRCacheEntryWithActiveSubscriptionAndDate(
    NSDate *lastReceiptValidationDate) {
  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:BZRReceiptValidationStatusWithExpiry(NO)
          cachingDateTime:lastReceiptValidationDate];
}

// Stubs loading cache entries via \c receiptValidationStatusProvider to return a dictionary
// containing bundleID mapped to a cache entry containing the given \c lastReceiptValidationDate.
static void BZRStubLoadedCacheEntryWithLastReceiptValidationDate(
    BZRReceiptValidationStatusCache *receiptValidationStatusCache,
    NSString *bundleID, NSDate *lastReceiptValidationDate) {
  auto cacheEntry = BZRCacheEntryWithActiveSubscriptionAndDate(lastReceiptValidationDate);
  BZRStubLoadedCacheEntries(receiptValidationStatusCache, @{bundleID: cacheEntry});
}

SpecBegin(BZRReceiptValidationDateProvider)

__block BZRReceiptValidationStatusCache *receiptValidationStatusCache;
__block BZRFakeAggregatedReceiptValidationStatusProvider *aggregatedReceiptValidationStatusProvider;
__block NSSet<NSString *> *bundledApplicationsIDs;
__block NSTimeInterval validationInterval;
__block BZRReceiptValidationDateProvider *validationDateProvider;

beforeEach(^{
  receiptValidationStatusCache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  bundledApplicationsIDs = @[@"foo", @"bar"].lt_set;
  aggregatedReceiptValidationStatusProvider =
      [[BZRFakeAggregatedReceiptValidationStatusProvider alloc] init];
  NSUInteger validationIntervalDays = 13;
  validationInterval = [BZRTimeConversion numberOfSecondsInDays:validationIntervalDays];
  validationDateProvider = [[BZRReceiptValidationDateProvider alloc]
      initWithReceiptValidationStatusCache:receiptValidationStatusCache
           receiptValidationStatusProvider:aggregatedReceiptValidationStatusProvider
                    bundledApplicationsIDs:bundledApplicationsIDs
                    validationIntervalDays:validationIntervalDays];
});

context(@"subscription doesn't exist", ^{
  it(@"should be nil if subscription is nil", ^{
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        [BZRReceiptValidationStatusWithExpiry(NO)
         modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptValidationStatus,
         receipt.subscription) withValue:nil];

    expect(validationDateProvider.nextValidationDate).to.beNil();
  });
});

context(@"subscription exists", ^{
  it(@"should be nil if subscription is cancelled", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, YES);
    LTAssert([receiptValidationStatus.receipt.subscription.expirationDateTime
        compare:receiptValidationStatus.validationDateTime] == NSOrderedDescending,
        @"Expected validation status with validation time prior to expiration time");

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

  it(@"should be nil if subscription was marked as expired before last validation", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    NSDate *postExpirationDateTime =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
            dateByAddingTimeInterval:1];

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        [receiptValidationStatus
            modelByOverridingProperty:@keypath(receiptValidationStatus, validationDateTime)
                            withValue:postExpirationDateTime];

    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

  it(@"should not be nil if subscription exists and is not marked as expired", ^{
    auto lastValidationDate = [NSDate dateWithTimeIntervalSince1970:2337];
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusCache,
        @"foo", lastValidationDate);
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(NO);

    expect(validationDateProvider.nextValidationDate).toNot.beNil();
  });

  it(@"should not be nil if subscription was marked as expired before expiration", ^{
    auto lastValidationDate = [NSDate dateWithTimeIntervalSince1970:2337];
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusCache,
        @"foo", lastValidationDate);
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(YES, NO);

    expect(validationDateProvider.nextValidationDate).toNot.beNil();
  });
});

context(@"calculating next validation date", ^{
  it(@"should compute next validation date to be the last validation date plus the time "
     "interval", ^{
    auto lastValidationDate = [NSDate dateWithTimeIntervalSince1970:2337];
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusCache,
                                                         @"foo", lastValidationDate);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(YES);
    expect(validationDateProvider.nextValidationDate).to
        .equal([lastValidationDate dateByAddingTimeInterval:validationInterval]);
  });

  it(@"should be nil if there is no last validation date", ^{
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(YES);
    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

  context(@"last validation dates of multiple applications", ^{
    it(@"should compute next validation date in relation to the earliest amongst the last "
       "validation dates", ^{
      NSDate *earlierDate = [NSDate dateWithTimeIntervalSince1970:30];
      NSDate *laterDate = [NSDate dateWithTimeIntervalSince1970:60];
      BZRStubLoadedCacheEntries(receiptValidationStatusCache, @{
        @"foo": BZRCacheEntryWithActiveSubscriptionAndDate(earlierDate),
        @"bar": BZRCacheEntryWithActiveSubscriptionAndDate(laterDate)
      });

      aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithExpiry(YES);

      expect(validationDateProvider.nextValidationDate).to
          .equal([earlierDate dateByAddingTimeInterval:validationInterval]);
    });
  });
});

SpecEnd
