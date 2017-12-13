// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

LTErrorCodesImplement(ShopixErrorCodeProductID,
  /// Caused when a promotion has expired.
  SPXErrorCodePromotionExpired,
  /// Caused when a promotion has conflicting coupons.
  SPXErrorCodeConflictingCouponsInPromotion,
  /// Caused when a coupon is invalid.
  SPXErrorCodeInvalidCoupon,
  /// Caused when a deserialization process failed.
  SPXErrorCodeDeserializationFailed,
  /// Caused when a serialization process failed.
  SPXErrorCodeSerializationFailed,
  /// Caused when data failed signature validation.
  SPXErrorCodeSignatureValidationFailed
);

NS_ASSUME_NONNULL_END
