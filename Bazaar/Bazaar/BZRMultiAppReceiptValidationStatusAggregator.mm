// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusAggregator.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel+HelperProperties.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMultiAppReceiptValidationStatusAggregator ()

/// Bundle identifier of the current application.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

/// Object used to determine whether a subscription product of other applications should be
/// considered a valid subscription for the current application.
@property (readonly, nonatomic, nullable) id<BZRMultiAppSubscriptionClassifier>
    multiAppSubscriptionClassifier;

@end

@implementation BZRMultiAppReceiptValidationStatusAggregator

- (instancetype)initWithCurrentApplicationBundleID:(NSString *)currentApplicationBundleID
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier {
  if (self = [super init]) {
    _currentApplicationBundleID = [currentApplicationBundleID copy];
    _multiAppSubscriptionClassifier = multiAppSubscriptionClassifier;
  }
  return self;
}

- (nullable BZRReceiptValidationStatus *)aggregateMultiAppReceiptValidationStatuses:
    (nullable BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus {
  static NSString * const kSubscriptionKeypath =
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription);

  if (!bundleIDToReceiptValidationStatus) {
    return nil;
  }

  if (![self relevantReceiptValidationStatuses:bundleIDToReceiptValidationStatus].count) {
    return nil;
  }

  auto receiptValidationStatusWithMostFitSubscription =
      [self receiptValidationStatusWithMostFitSubscripition:bundleIDToReceiptValidationStatus];
  return bundleIDToReceiptValidationStatus[self.currentApplicationBundleID] ?
      [bundleIDToReceiptValidationStatus[self.currentApplicationBundleID]
       modelByOverridingPropertyAtKeypath:kSubscriptionKeypath
       withValue:receiptValidationStatusWithMostFitSubscription.receipt.subscription] :
      [self receiptValidationStatusWithFieldsFromRelevantStatus:
       receiptValidationStatusWithMostFitSubscription];
}

- (BZRMultiAppReceiptValidationStatus *)relevantReceiptValidationStatuses:
    (BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus {
  return [bundleIDToReceiptValidationStatus lt_filter:^BOOL(NSString *bundleID,
      BZRReceiptValidationStatus *receiptValidationStatus) {
    return ([bundleID isEqualToString:self.currentApplicationBundleID] ||
        [self hasRelevantMultiAppSubscription:receiptValidationStatus]);
  }];
}

- (BOOL)hasRelevantMultiAppSubscription:(BZRReceiptValidationStatus *)receiptValidationStatus {
  return [self.multiAppSubscriptionClassifier
          isMultiAppSubscription:receiptValidationStatus.receipt.subscription.productId];
}

- (BZRReceiptValidationStatus *)receiptValidationStatusWithMostFitSubscripition:
    (BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus {
  auto relevantReceiptValidationStatuses =
      [self relevantReceiptValidationStatuses:bundleIDToReceiptValidationStatus].allValues;

  return lt::nn([relevantReceiptValidationStatuses sortedArrayUsingDescriptors:@[
    [self activeSubscriptionSortDescriptor],
    [self effectiveExpirationDateSortDescriptor]
  ]].firstObject);
}

- (NSSortDescriptor *)activeSubscriptionSortDescriptor {
  return [NSSortDescriptor sortDescriptorWithKey:
     @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription.isActive)
     ascending:NO];
}

- (NSSortDescriptor *)effectiveExpirationDateSortDescriptor {
  return [NSSortDescriptor sortDescriptorWithKey:
     @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription.effectiveExpirationDate)
     ascending:NO];
}

- (BZRReceiptValidationStatus *)receiptValidationStatusWithFieldsFromRelevantStatus:
    (BZRReceiptValidationStatus *)relevantReceiptValidationStatus {
  BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, subscription):
        relevantReceiptValidationStatus.receipt.subscription
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt,
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime):
        relevantReceiptValidationStatus.validationDateTime,
    @instanceKeypath(BZRReceiptValidationStatus, requestId):
        relevantReceiptValidationStatus.requestId
  } error:nil];
}

@end

NS_ASSUME_NONNULL_END
