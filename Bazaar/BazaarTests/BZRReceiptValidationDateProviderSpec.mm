// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationDateProvider.h"

#import "BZRFakeMultiAppReceiptValidationStatusProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"

SpecBegin(BZRReceiptValidationDateProvider)

__block BZRFakeMultiAppReceiptValidationStatusProvider *multiAppReceiptValidationStatusProvider;
__block NSTimeInterval validationInterval;
__block BZRReceiptValidationDateProvider *validationDateProvider;

beforeEach(^{
  multiAppReceiptValidationStatusProvider =
      [[BZRFakeMultiAppReceiptValidationStatusProvider alloc] init];
  NSUInteger validationIntervalDays = 13;
  validationInterval = [BZRTimeConversion numberOfSecondsInDays:validationIntervalDays];
  validationDateProvider =
      [[BZRReceiptValidationDateProvider alloc]
       initWithReceiptValidationStatusProvider:multiAppReceiptValidationStatusProvider
       validationIntervalDays:validationIntervalDays];
});

context(@"subscription doesn't exist", ^{
  it(@"should be nil if subscription is nil", ^{
    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
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

    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
        receiptValidationStatus;

    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

  it(@"should be nil if subscription was marked as expired before last validation", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    NSDate *postExpirationDateTime =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
            dateByAddingTimeInterval:1];

    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
        [receiptValidationStatus
            modelByOverridingProperty:@keypath(receiptValidationStatus, validationDateTime)
                            withValue:postExpirationDateTime];

    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

  it(@"should not be nil if subscription exists and is not marked as expired", ^{
    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(NO);

    expect(validationDateProvider.nextValidationDate).toNot.beNil();
  });

  it(@"should not be nil if subscription was marked as expired before expiration", ^{
    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(YES, NO);

    expect(validationDateProvider.nextValidationDate).toNot.beNil();
  });
});

context(@"calculating next validation date", ^{
  it(@"should compute next validation date to be the last validation date plus the time "
     "interval", ^{
    auto lastValidationDate = [NSDate dateWithTimeIntervalSince1970:2337];

    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus =
        [BZRReceiptValidationStatusWithExpiry(YES)
         modelByOverridingPropertyAtKeypath:
         @instanceKeypath(BZRReceiptValidationStatus, validationDateTime)
         withValue:lastValidationDate];

    expect(validationDateProvider.nextValidationDate).to
        .equal([lastValidationDate dateByAddingTimeInterval:validationInterval]);
  });

  it(@"should be nil if there is no receipt validation status", ^{
    multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus = nil;
    expect(validationDateProvider.nextValidationDate).to.beNil();
  });

});

SpecEnd
