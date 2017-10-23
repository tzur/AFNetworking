// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

@class SPXCoupon, SPXPromotion;

@interface NSError (Shopix)

/// Creates an error with Lightricks' domain, given error code and the associated promotion.
+ (instancetype)spx_errorWithCode:(NSInteger)code
              associatedPromotion:(SPXPromotion *)associatedPromotion;

/// Creates an error with Lightricks' domain, given error code, the associated promotion and the
/// associated coupon.
+ (instancetype)spx_errorWithCode:(NSInteger)code
              associatedPromotion:(SPXPromotion *)associatedPromotion
                 associatedCoupon:(SPXCoupon *)associatedCoupon;

/// Promotion associated with the error.
@property (readonly, nonatomic, nullable) SPXPromotion *spx_associatedPromotion;

/// Coupon associated with the error.
@property (readonly, nonatomic, nullable) SPXPromotion *spx_associatedCoupon;

@end

NS_ASSUME_NONNULL_END
