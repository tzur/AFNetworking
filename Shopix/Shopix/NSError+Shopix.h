// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

@class SPXCoupon, SPXVoucher;

@interface NSError (Shopix)

/// Creates an error with Lightricks' domain, given error code and the associated voucher.
+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher;

/// Creates an error with Lightricks' domain, given error code, associated voucher and an
/// underlying error.
+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher
                  underlyingError:(NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code, the associated voucher and the
/// associated coupon.
+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher
                 associatedCoupon:(SPXCoupon *)associatedCoupon;

/// Voucher associated with the error.
@property (readonly, nonatomic, nullable) SPXVoucher *spx_associatedVoucher;

/// Coupon associated with the error.
@property (readonly, nonatomic, nullable) SPXCoupon *spx_associatedCoupon;

@end

NS_ASSUME_NONNULL_END
