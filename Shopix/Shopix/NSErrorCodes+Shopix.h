// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Shopix.
  ShopixErrorCodeProductID = 14
};

/// All error codes available in Shopix.
LTErrorCodesDeclare(ShopixErrorCodeProductID,
  /// Caused when a promotion has expired.
  SPXErrorCodePromotionExpired,
  /// Caused when a promotion has conflicting coupons.
  SPXErrorCodeConflictingCouponsInPromotion,
  /// Caused when a coupon is invalid.
  SPXErrorCodeInvalidCoupon,
  /// Caused when a deserialization process failed.
  SPXErrorCodeDeserializationFailed
);

NS_ASSUME_NONNULL_END
