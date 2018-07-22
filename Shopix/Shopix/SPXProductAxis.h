// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPXProductAxisValue;

@class SPXBenefitAxisValue;

/// One Axis in the products matrix. An axis represents a certain attribute of the product like
/// subscription period or license type. Each axis has a few values a product can have for that
/// axis.
///
/// The product matrix is built from a set of such axes. Selecting a value from each axis in the
/// matrix yields unique product for that combination of values.
@protocol SPXProductAxis <NSObject>

/// Possible values for the axis.
@property (readonly, nonatomic) NSArray<id<SPXProductAxisValue>> *values;

@end

/// Value of any product \c axis. For example, for the discount axis, \c value will be one of
/// ["FullPrice", "25Off", "50Off", "75Off"], while \c axis will point to the discount axis object.
@protocol SPXProductAxisValue <NSObject>

/// Value of the \c axis, used to compound product identifier.
@property (readonly, nonatomic) NSString *value;

/// Axis of this value.
@property (readonly, nonatomic) id<SPXProductAxis> axis;

@end

/// Axis specifying a part of a product, i.e. subscription length for subscription products.
/// Directly affects the contents of the product - product with different value for this axis,
/// represent different products.
@protocol SPXBaseProductAxis <SPXProductAxis>;
@end

/// Axis that describes a level of benefit of a product and does not change the product itself.
/// products with the same base product values and different benefit value represent the same
/// products but with different benefit for the user. For example price discount.
@protocol SPXBenefitAxis <SPXProductAxis>;

/// Value of this axis, when there is no benefit. For example, full price for discount axis.
@property (readonly, nonatomic) SPXBenefitAxisValue *defaultValue;

@end

/// Value of a base product axis.
@interface SPXBaseProductAxisValue : LTValueObject <SPXProductAxisValue>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c value and \c axis of the value.
- (instancetype)initWithValue:(NSString *)value andAxis:(id<SPXBaseProductAxis>)axis
    NS_DESIGNATED_INITIALIZER;

/// Returns an initialized value with the given \c value and \c axis of the value.
+ (instancetype)axisValueWithValue:(NSString *)value andAxis:(id<SPXBaseProductAxis>)axis;

/// Axis of the value.
@property (readonly, nonatomic) id<SPXBaseProductAxis> axis;

@end

/// Value of a benefit axis.
@interface SPXBenefitAxisValue : LTValueObject <SPXProductAxisValue>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c value and \c axis of the value.
- (instancetype)initWithValue:(NSString *)value andAxis:(id<SPXBenefitAxis>)axis
    NS_DESIGNATED_INITIALIZER;

/// Returns an initialized axis value with the given \c value and \c axis.
+ (instancetype)axisValueWithValue:(NSString *)value andAxis:(id<SPXBenefitAxis>)axis;

/// Axis of the value.
@property (readonly, nonatomic) id<SPXBenefitAxis> axis;

@end

/// Benefit axis describing the discount percentage a product has, defaults to \c fullPrice.
@interface SPXBenefitProductAxisDiscountLevel : LTValueObject <SPXBenefitAxis>

/// Full price.
@property (readonly, nonatomic) SPXBenefitAxisValue *fullPrice;

/// 10% Off.
@property (readonly, nonatomic) SPXBenefitAxisValue *off10;

/// 25% Off.
@property (readonly, nonatomic) SPXBenefitAxisValue *off25;

/// 50% Off.
@property (readonly, nonatomic) SPXBenefitAxisValue *off50;

/// 75% Off.
@property (readonly, nonatomic) SPXBenefitAxisValue *off75;

@end

/// Benefit axis describing the duration a subscription product is free, defaults to \c noTrial.
@interface SPXBenefitProductAxisFreeTrialDuration : LTValueObject <SPXBenefitAxis>

/// Subscription with no trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *noTrial;

/// Subscription with three days trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *threeDaysTrial;

/// Subscription with one week trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *oneWeekTrial;

/// Subscription with one month trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *oneMonthTrial;

/// Subscription with three months trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *threeMonthsTrial;

/// Subscription with six months trial.
@property (readonly, nonatomic) SPXBenefitAxisValue *sixMonthsTrial;

@end

/// Base product axis describing the subscription duration of the product.
@interface SPXBaseProductAxisSubscriptionPeriod : LTValueObject <SPXBaseProductAxis>

/// Billed once.
@property (readonly, nonatomic) SPXBaseProductAxisValue *oneTimePayment;

/// Subscription based product, billed each month.
@property (readonly, nonatomic) SPXBaseProductAxisValue *monthly;

/// Subscription based product, billed each 6 month.
@property (readonly, nonatomic) SPXBaseProductAxisValue *biYearly;

/// Subscription based product, billed once a year.
@property (readonly, nonatomic) SPXBaseProductAxisValue *yearly;

@end

/// Factory class for creating base product axis objects.
@interface SPXBaseProductAxis : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new \c SPXBaseProductAxisSubscriptionPeriod object.
@property (class, readonly, nonatomic) SPXBaseProductAxisSubscriptionPeriod *subscriptionPeriod;

@end

/// Factory class for creating benefit axis objects.
@interface SPXBenefitProductAxis : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new \c SPXBenefitProductAxisDiscountLevel object.
@property (class, readonly, nonatomic) SPXBenefitProductAxisDiscountLevel *discountLevel;

/// Returns a new \c SPXBenefitProductAxisFreeTrialDuration object.
@property (class, readonly, nonatomic) SPXBenefitProductAxisFreeTrialDuration *freeTrialDuration;

@end

NS_ASSUME_NONNULL_END
