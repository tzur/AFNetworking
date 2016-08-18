// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptSubscriptionInfo, BZRReceiptValidationStatusProvider;
@protocol BZRTimeProvider;

/// Verifier that verifies whether the user is allowed to use a certain product.
@interface BZRProductEligibilityVerifier : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c receiptValidationStatusProvider, used to fetch the latest receipt
/// validation status that is used to verify eligibility. \c timeProvider is used to check if the
/// expired subscription grace period is over. \c expiredSubscriptionGracePeriod specifies how many
/// grace days period the user is allowed to use products that he acquired via subscription after
/// its subscription has been expired.
- (instancetype)initWithReceiptValidationStatusProvider:(BZRReceiptValidationStatusProvider *)
    receiptValidationStatusProvider timeProvider:(id<BZRTimeProvider>)timeProvider
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Verifies that the user is allowed to use the product specified by \c productIdentifier. The user
/// is allowed to use a product if he purchased it or if he purchased a subscription that grants him
/// the right to use the product. This method determines whether the user is allowed to use a
/// product based on the receipt validation status.
///
/// Returns a signal that sends a single \c NSNumber value boxing a \c BOOL value. The boxed value
/// will be \c YES if the user is allowed to use the product, otherwise it will be \c NO. The signal
/// completes after sending the value.  The signal errs if the receipt validation status couldn't be
/// obtained.
///
/// @return <tt>RACSignal<NSNumber></tt>
///
/// @note If the subscription is expired and the grace period is not over, the user is still allowed
/// to use the product.
- (RACSignal *)verifyEligibilityForProduct:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
