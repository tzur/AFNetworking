// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductEligibilityVerifier.h"

#import "BZRProduct.h"
#import "BZRReceiptModel+ProductPurchased.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"
#import "BZRTimeConversion.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductEligibilityVerifier ()

/// Provider that provides \c BZRReceiptValidationStatus.
@property (readonly, nonatomic) BZRReceiptValidationStatusProvider *receiptValidationStatusProvider;

/// Provider used to check if the expired subscription grace period is over.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Specifies the number of days the user is allowed to use products that he acquired via
/// subscription after its subscription has been expired.
@property (readonly, nonatomic) NSTimeInterval expiredSubscriptionGracePeriodSeconds;

@end

@implementation BZRProductEligibilityVerifier

- (instancetype)initWithReceiptValidationStatusProvider:(BZRReceiptValidationStatusProvider *)
    receiptValidationStatusProvider timeProvider:(id<BZRTimeProvider>)timeProvider
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod {
  if (self = [super init]) {
    _receiptValidationStatusProvider = receiptValidationStatusProvider;
    _timeProvider = timeProvider;
    _expiredSubscriptionGracePeriodSeconds =
        [BZRTimeConversion numberOfSecondsInDays:expiredSubscriptionGracePeriod];
  }
  return self;
}

- (RACSignal *)verifyEligibilityForProduct:(NSString *)productIdentifier {
  @weakify(self);
  return [[[RACSignal defer:^RACSignal *{
    @strongify(self);
    return [RACSignal return:self.receiptValidationStatusProvider.receiptValidationStatus];
  }] flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
    @strongify(self);
    return receiptValidationStatus ? [RACSignal return:receiptValidationStatus] :
        [self.receiptValidationStatusProvider validateReceipt];
  }] flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
    @strongify(self);
    return [self isUserAllowedToUseProduct:productIdentifier
                   receiptValidationStatus:receiptValidationStatus];
  }];
}

- (RACSignal *)isUserAllowedToUseProduct:(NSString *)productIdentifier
                 receiptValidationStatus:(BZRReceiptValidationStatus *)receiptValidationStatus {
  return [receiptValidationStatus.receipt wasProductPurchased:productIdentifier] ?
      [RACSignal return:@YES] :
      [self checkEligibilityForProductViaSubscription:receiptValidationStatus.receipt];
}

- (RACSignal *)checkEligibilityForProductViaSubscription:(BZRReceiptInfo *)receipt {
  if (!receipt.subscription) {
    return [RACSignal return:@(NO)];
  }
  return receipt.subscription.isExpired ? [self isGracePeriodNotOver:receipt.subscription] :
      [RACSignal return:@(YES)];
}

- (RACSignal *)isGracePeriodNotOver:(BZRReceiptSubscriptionInfo *)subscription {
  @weakify(self);
  return [[self.timeProvider currentTime] map:^NSNumber *(NSDate *currentTime) {
    @strongify(self);
    NSDate *expirationDatePlusGracePeriod = [subscription.expirationDateTime
        dateByAddingTimeInterval:self.expiredSubscriptionGracePeriodSeconds];
    return @([expirationDatePlusGracePeriod compare:currentTime] == NSOrderedDescending);
  }];
}

@end

NS_ASSUME_NONNULL_END
