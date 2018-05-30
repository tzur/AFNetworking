// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

LTErrorCodesImplement(ShopixErrorCodeProductID,
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
  SPXErrorCodeSignatureValidationFailed,
  /// Caused when failed to calculate order summary of consumable items.
  SPXErrorCodeConsumablesOrderSummaryCalculationFailed,
  /// Caused when failed to place order of consumable items.
  SPXErrorCodeConsumablesPlacingOrderFailed
);

NS_ASSUME_NONNULL_END
