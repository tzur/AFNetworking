// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusAggregator.h"

#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel+HelperProperties.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"

SpecBegin(BZRMultiAppReceiptValidationStatusAggregator)

__block NSString *currentApplicationBundleID;
__block NSString *multiAppSubscriptionMarker;
__block id<BZRMultiAppSubscriptionClassifier> multiAppSubscriptionClassifier;
__block BZRMultiAppReceiptValidationStatusAggregator *aggregator;

beforeEach(^{
  currentApplicationBundleID = @"com.lt.foo";
  multiAppSubscriptionMarker = @".all";
  multiAppSubscriptionClassifier = OCMProtocolMock(@protocol(BZRMultiAppSubscriptionClassifier));
  OCMStub([multiAppSubscriptionClassifier
           isMultiAppSubscription:[OCMArg checkWithBlock:^BOOL(NSString *productId) {
    return [productId containsString:multiAppSubscriptionMarker];
  }]]).andReturn(YES);
  aggregator = [[BZRMultiAppReceiptValidationStatusAggregator alloc]
                initWithCurrentApplicationBundleID:currentApplicationBundleID
                multiAppSubscriptionClassifier:multiAppSubscriptionClassifier];
});

context(@"aggregating receipt validation statuses correctly", ^{
  static NSString * const subscriptionKeypath =
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription);
  static NSString * const isExpiredKeypath =
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription.isExpired);
  static NSString * const expirationDateTimeKeypath =
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription.expirationDateTime);

  __block BZRReceiptValidationStatus *currentAppReceiptValidationStatus;

  beforeEach(^{
    currentAppReceiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", NO);
  });

  it(@"should ignore other applications subscriptions if multi app subscription classifier is nil",
     ^{
    BZRReceiptValidationStatus *currentAppReceiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(YES);
    BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all");

    auto bundleIDToReceiptValidationStatus = @{
      currentApplicationBundleID: currentAppReceiptValidationStatus,
      @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus
    };

    aggregator = [[BZRMultiAppReceiptValidationStatusAggregator alloc]
                  initWithCurrentApplicationBundleID:currentApplicationBundleID
                  multiAppSubscriptionClassifier:nil];
    auto aggregatedReceiptValidationStatus =
        [aggregator aggregateMultiAppReceiptValidationStatuses:bundleIDToReceiptValidationStatus];

    expect(aggregatedReceiptValidationStatus).to.equal(currentAppReceiptValidationStatus);
  });

  context(@"no multi app subscription of other applications", ^{
    it(@"should return subscription of the current application", ^{
      BZRReceiptValidationStatus *otherAppReceiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo");

      auto bundleIDToReceiptValidationStatus = @{
        currentApplicationBundleID: currentAppReceiptValidationStatus,
        @"com.lt.otherApp": otherAppReceiptValidationStatus
      };

      expect([aggregator aggregateMultiAppReceiptValidationStatuses:
              bundleIDToReceiptValidationStatus]).to.equal(currentAppReceiptValidationStatus);
    });

    it(@"should return multi app subscription of the current application", ^{
      currentAppReceiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all");

      auto bundleIDToReceiptValidationStatus = @{
        currentApplicationBundleID: currentAppReceiptValidationStatus,
      };

      expect([aggregator aggregateMultiAppReceiptValidationStatuses:
              bundleIDToReceiptValidationStatus]).to.equal(currentAppReceiptValidationStatus);
    });

    it(@"should return expired subscription of the current application even if another "
       "non-relevant subscription exists", ^{
      currentAppReceiptValidationStatus =
          [currentAppReceiptValidationStatus modelByOverridingPropertyAtKeypath:isExpiredKeypath
                                                                      withValue:@YES];
      BZRReceiptValidationStatus *otherAppReceiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo");

      auto bundleIDToReceiptValidationStatus = @{
        currentApplicationBundleID: currentAppReceiptValidationStatus,
        @"com.lt.otherApp": otherAppReceiptValidationStatus
      };

      expect([aggregator aggregateMultiAppReceiptValidationStatuses:
              bundleIDToReceiptValidationStatus]).to.equal(currentAppReceiptValidationStatus);
    });
  });

  context(@"with multi app subscription", ^{
    it(@"should ignore another application's subscription if its identifier doesn't contain the "
       "given multi app subscription marker", ^{
      BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.otherMulti");

      auto bundleIDToReceiptValidationStatus = @{
        currentApplicationBundleID: currentAppReceiptValidationStatus,
        @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus
      };

      expect([aggregator aggregateMultiAppReceiptValidationStatuses:
              bundleIDToReceiptValidationStatus]).to.equal(currentAppReceiptValidationStatus);
    });

    context(@"taking the subscription with the farthest date", ^{
      it(@"should take the subscription with the farthest effective expiration date amongst the "
         "active subscriptions", ^{
        currentAppReceiptValidationStatus =
            [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:90]];
        BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
            [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:120]];
        BZRReceiptValidationStatus *anotherAppReceiptReceiptValidationStatus =
            [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:60]];

        auto bundleIDToReceiptValidationStatus = @{
          currentApplicationBundleID: currentAppReceiptValidationStatus,
          @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus,
          @"com.lt.anotherApp": anotherAppReceiptReceiptValidationStatus
        };

        auto expectedReceiptValidationStatus = [currentAppReceiptValidationStatus
            modelByOverridingPropertyAtKeypath:subscriptionKeypath
            withValue:otherAppReceiptReceiptValidationStatus.receipt.subscription];
        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
                bundleIDToReceiptValidationStatus]).to.equal(expectedReceiptValidationStatus);
      });

      it(@"should take the subscription with the farthest effective expiration date amongst the "
         "non active subscriptions", ^{
        static NSString * const cancellationDateTimeKeypath =
            @instanceKeypath(BZRReceiptValidationStatus,
                             receipt.subscription.cancellationDateTime);

        currentAppReceiptValidationStatus =
            [[BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:90]]
             modelByOverridingPropertyAtKeypath:cancellationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:90]];
        BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
            [[BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:120]]
             modelByOverridingPropertyAtKeypath:cancellationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:70]];
        BZRReceiptValidationStatus *anotherAppReceiptReceiptValidationStatus =
            [[BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:60]]
             modelByOverridingPropertyAtKeypath:cancellationDateTimeKeypath
             withValue:[NSDate dateWithTimeIntervalSince1970:130]];

        auto bundleIDToReceiptValidationStatus = @{
          currentApplicationBundleID: currentAppReceiptValidationStatus,
          @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus,
          @"com.lt.anotherApp": anotherAppReceiptReceiptValidationStatus
        };

        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
                bundleIDToReceiptValidationStatus]).to.equal(currentAppReceiptValidationStatus);
      });
    });

    it(@"should use the multi app subscription of another application if the subscription of the "
       "current application is not active", ^{
      currentAppReceiptValidationStatus =
          [[BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo")
           modelByOverridingPropertyAtKeypath:isExpiredKeypath withValue:@YES]
           modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
           withValue:[NSDate dateWithTimeIntervalSince1970:120]];
      BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
          [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
           modelByOverridingPropertyAtKeypath:expirationDateTimeKeypath
           withValue:[NSDate dateWithTimeIntervalSince1970:90]];

      auto bundleIDToReceiptValidationStatus = @{
        currentApplicationBundleID: currentAppReceiptValidationStatus,
        @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus
      };

      auto expectedReceiptValidationStatus = [currentAppReceiptValidationStatus
          modelByOverridingPropertyAtKeypath:subscriptionKeypath
          withValue:otherAppReceiptReceiptValidationStatus.receipt.subscription];
        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
                bundleIDToReceiptValidationStatus]).to.equal(expectedReceiptValidationStatus);
    });

    context(@"current application receipt validation status wasn't fetched successfully", ^{
      it(@"should return a newly created receipt validation status with the receipt validation "
         "status with the most fit subscription and validation date time", ^{
        BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
            BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all");

        auto bundleIDToReceiptValidationStatus = @{
          @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus
        };

        BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
          @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
          @instanceKeypath(BZRReceiptInfo, subscription):
              otherAppReceiptReceiptValidationStatus.receipt.subscription
        } error:nil];
        BZRReceiptValidationStatus *expectedReceiptValidationStatus =
           [BZRReceiptValidationStatus modelWithDictionary:@{
             @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt,
             @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
             @instanceKeypath(BZRReceiptValidationStatus, validationDateTime):
                 otherAppReceiptReceiptValidationStatus.validationDateTime
           } error:nil];
        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
                bundleIDToReceiptValidationStatus]).to.equal(expectedReceiptValidationStatus);
      });

      it(@"should return the only non-expired multi app subscription", ^{
        BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
            BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all");
        BZRReceiptValidationStatus *anotherAppReceiptReceiptValidationStatus =
            [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:isExpiredKeypath withValue:@YES];

        auto bundleIDToReceiptValidationStatus = @{
          @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus,
          @"com.lt.anotherApp": anotherAppReceiptReceiptValidationStatus
        };

        auto expectedAppReceiptReceiptValidationStatus = [otherAppReceiptReceiptValidationStatus
            modelByOverridingPropertyAtKeypath:
            @instanceKeypath(BZRReceiptValidationStatus, receipt.transactions) withValue:@[]];
        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
            bundleIDToReceiptValidationStatus]).to.equal(expectedAppReceiptReceiptValidationStatus);
      });

      it(@"should return the only non-cancelled multi app subscription", ^{
        BZRReceiptValidationStatus *otherAppReceiptReceiptValidationStatus =
            BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all");
        BZRReceiptValidationStatus *anotherAppReceiptReceiptValidationStatus =
            [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"com.lt.all")
             modelByOverridingPropertyAtKeypath:
             @instanceKeypath(BZRReceiptValidationStatus,
                              receipt.subscription.cancellationDateTime)
             withValue:[NSDate date]];

        auto bundleIDToReceiptValidationStatus = @{
          @"com.lt.otherApp": otherAppReceiptReceiptValidationStatus,
          @"com.lt.anotherApp": anotherAppReceiptReceiptValidationStatus
        };

        auto expectedAppReceiptReceiptValidationStatus = [otherAppReceiptReceiptValidationStatus
            modelByOverridingPropertyAtKeypath:
            @instanceKeypath(BZRReceiptValidationStatus, receipt.transactions) withValue:@[]];
        expect([aggregator aggregateMultiAppReceiptValidationStatuses:
            bundleIDToReceiptValidationStatus]).to.equal(expectedAppReceiptReceiptValidationStatus);
      });
    });
  });
});

SpecEnd
