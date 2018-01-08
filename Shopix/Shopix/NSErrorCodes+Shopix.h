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
  /// Caused when a voucher has expired.
  SPXErrorCodeVoucherExpired,
  /// Caused when a two or more coupons conflict.
  SPXErrorCodeConflictingCoupons,
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
