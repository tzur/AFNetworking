// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class SPXBaseProductAxisValue, SPXBenefitAxisValue;

@protocol SPXProductAxisValue;

/// Value object defining which benefit axis values to apply on which base axis values.
@interface SPXCoupon : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c baseProductValues as the values to apply \c benefitValues on.
/// \c benefitValues will be applied on *all* products with \c baseProductValues.
///
/// Any value is allowed in \c baseProductValues, even from the same axis. This allow creating
/// coupons that affect multiple products.
///
/// @note \c benefitValues must not specify multiple values for the same axis.
///
/// @important Any axis in the product matrix, but not in any value in \c baseProductValues, will
/// also have \c benefitValues applied on.
///
/// @example If the product matrix has 2 base product axes, A and B, with values X, Y and U, V
/// respectively, and \c baseProductValues is set to be X. Both products X.U and X.V will get
/// \c benefitValues.
- (instancetype)initWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                            benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues
    NS_DESIGNATED_INITIALIZER;

/// Returns a new coupon with \c baseProductValues as the values to apply \c benefitValues on.
///
/// @see \c initWithBaseProductValues:benefitValues:
+ (instancetype)couponWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                              benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues;

/// Product with these base product values will have \c benefitValues.
@property (readonly, nonatomic) NSArray<SPXBaseProductAxisValue *> *baseProductValues;

/// Benefit values to apply on products with \c baseProductValues.
@property (readonly, nonatomic) NSArray<SPXBenefitAxisValue *> *benefitValues;

@end

/// Value object containing coupons and expiry date grouped together to represent a single
/// promotion.
///
/// A promotion can be applied on base product values, to get a product descriptors.
/// @see [SPXProductDescriptorsFactory productDescriptorsWithPromotion:withError:]
@interface SPXPromotion : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c name to identify the promotion, \c coupons to apply on base
/// products and \c expiryDate as the last date this promotion can be used (in UTC).
///
/// @note This class does not check for the validity of the \c coupons, as they can conflict.
/// Validity is checked when applying the coupon.
- (instancetype)initWithName:(NSString *)name coupons:(NSArray<SPXCoupon *> *)coupons
                  expiryDate:(NSDate *)expiryDate NS_DESIGNATED_INITIALIZER;

/// Name of the promotion.
@property (readonly, nonatomic) NSString *name;

/// All the coupons in this promotion.
@property (readonly, nonatomic) NSArray<SPXCoupon *> *coupons;

/// Expirty date for this promotion. The last date in UTC this promotion is valid.
@property (readonly, nonatomic) NSDate *expiryDate;

@end

NS_ASSUME_NONNULL_END
