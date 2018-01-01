// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRBillingPeriod;

#pragma mark -
#pragma mark BZRIntroductoryDiscountType
#pragma mark -

/// Different types of introductory discounts available for a subscription product. All discounts
/// are given for a limited time that can not exceed 1 year, when the discount duration ends the
/// subscription will automatically renew with the full subscription price.
///
/// Introductory discount  is only offered for the user once per subscription group, meaning if the
/// user already got a discount for some product within a subscription group he will not be
/// eligible for another introductory discount for other products in the same group, but he may be
/// eligible for another introductory discount for other products in a different group.
LTEnumDeclare(NSUInteger, BZRIntroductoryDiscountType,
  /// User pays a discounted price for some predefined duration. The discount duration must be an
  /// integer multiply of the subscription period, the multiplication factor must be <= 12 and the
  /// entire discount duration can not be longer than 1 year. For example if the subscription
  /// period is 3 months - the discount duration can be 3, 6, 9 or 12 months, if the subscription
  /// period is 1 week - the discount duration can be 1, 2, ..., 12 weeks. The payment is charged
  /// at the begning of each subscription period and there should be a payment transaction for
  /// each subscription period that is marked as an introductry discount period.
  BZRIntroductoryDiscountTypePayAsYouGo,

  /// User pays a discounted price in advance for some predefined duration. The discount duration
  /// can be 1, 2, 3, 6 months or 1 year, regardless of the billing period of the original product.
  /// The payment for the entire duration is charged at the moment of the purchase and there should
  /// be a single transaction for the entire period that is marked as an introductory discount
  /// period.
  BZRIntroductoryDiscountTypePayUpFront,

  /// User gets the subscription free of charge for some predfined duration. The discount duration
  /// can be 3 days; 1 or 2 weeks; 1, 2, 3 or 6 months or 1 year. The user is not charged until the
  /// free trial duration is over and there should be a single transaction for the entire period
  /// that is marked as an introductory discount period.
  BZRIntroductoryDiscountTypeFreeTrial
);

#pragma mark -
#pragma mark BZRSubscriptionIntroductoryDiscount
#pragma mark -

/// Represents an introductory discount that can be offered for a renewable subscription product.
@interface BZRSubscriptionIntroductoryDiscount : BZRModel <MTLJSONSerializing>

/// Type of the introductory discount.
@property (readonly, nonatomic) BZRIntroductoryDiscountType *discountType;

/// The discounted price during the introductory discount period.
@property (readonly, nonatomic, nullable) NSDecimalNumber *price;

/// The duration of each introductory discount billing period.
///
/// @note For introductory discounts of type \c BZRIntroductoryDiscountTypePayUpFront and
/// \c BZRIntroductoryDiscountTypeFreeTrial there's only \c 1 billing period.
@property (readonly, nonatomic) BZRBillingPeriod *billingPeriod;

/// Number of billing periods for which the introductory price is available for.
@property (readonly, nonatomic) NSUInteger numberOfPeriods;

/// Full duration of the introductory discount with \c unit set to to \c billingPeriod.unit and
/// \c unitCount set to <tt>numberOfPeriods * billingPeriod.unitCount</tt>.
@property (readonly, nonatomic) BZRBillingPeriod *duration;

@end

NS_ASSUME_NONNULL_END
