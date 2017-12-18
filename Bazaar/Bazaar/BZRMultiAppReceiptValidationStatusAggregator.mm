// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusAggregator.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel+HelperProperties.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMultiAppReceiptValidationStatusAggregator ()

/// Bundle identifier of the current application.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

/// Substring of subscription identifier. Subscription whose identifier contains this marker as a
/// substring is considered a relevant multi app subscription for the current application.
@property (readonly, nonatomic, nullable) NSString *multiAppSubscriptionIdentifierMarker;

@end

@implementation BZRMultiAppReceiptValidationStatusAggregator

- (instancetype)initWithCurrentApplicationBundleID:(NSString *)currentApplicationBundleID
    multiAppSubscriptionIdentifierMarker:(nullable NSString *)multiAppSubscriptionIdentifierMarker {
  if (self = [super init]) {
    _currentApplicationBundleID = [currentApplicationBundleID copy];
    _multiAppSubscriptionIdentifierMarker = [multiAppSubscriptionIdentifierMarker copy];
  }
  return self;
}

- (nullable BZRReceiptValidationStatus *)aggregateMultiAppReceiptValidationStatuses:
    (BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus {
  static NSString * const kSubscriptionKeypath =
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription);

  if (![self relevantReceiptValidationStatuses:bundleIDToReceiptValidationStatus].count) {
    return nil;
  }

  auto receiptValidationStatusWithMostFitSubscription =
      [self receiptValidationStatusWithMostFitSubscripition:bundleIDToReceiptValidationStatus];
  return bundleIDToReceiptValidationStatus[self.currentApplicationBundleID] ?
      [bundleIDToReceiptValidationStatus[self.currentApplicationBundleID]
       modelByOverridingPropertyAtKeypath:kSubscriptionKeypath
       withValue:receiptValidationStatusWithMostFitSubscription.receipt.subscription] :
      [self receiptValidationStatusWithSubscriptionAndValidationDateTime:
       receiptValidationStatusWithMostFitSubscription.receipt.subscription
       validationDateTime:receiptValidationStatusWithMostFitSubscription.validationDateTime];
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
  return self.multiAppSubscriptionIdentifierMarker &&
      [receiptValidationStatus.receipt.subscription.productId
       containsString:self.multiAppSubscriptionIdentifierMarker];
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

- (BZRReceiptValidationStatus *)receiptValidationStatusWithSubscriptionAndValidationDateTime:
    (BZRReceiptSubscriptionInfo *)subscription validationDateTime:(NSDate *)validationDateTime {
  BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, subscription): subscription
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt,
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): validationDateTime
  } error:nil];
}

@end

NS_ASSUME_NONNULL_END
