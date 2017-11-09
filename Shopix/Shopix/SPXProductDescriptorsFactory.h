// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@class SPXBaseProductAxisValue, SPXProductDescriptor, SPXPromotion;

@protocol SPXProductAxis;

/// Uses product matrix to create \c SPXProductDescriptor objects from base products and promotions.
/// The class creates product descriptors for a given array of base product defined by providing
/// values to each base product axis. Once the class is initialized with the matrix axes and the
/// base products, product descriptors can be generated for the base products with or without
/// promotions.
///
/// The products matrix has several axes, an axis can be either a base product axis or a benefit
/// axis.
///
/// The identifier of the resulted product is defined as:
/// "<prefix>.<version>.<axis 1 value>...<axis n value>".
///
/// @example A base product axis describes the product itself, like subscription length or type of
/// product. When values are given for all base product axis of a product matrix, a base product is
/// defined, but without any benefit value.
@interface SPXProductDescriptorsFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productsAxes as the axes of the products matrix. \c version and \c prefix
/// to perpend the product indentifier and \c baseProductValues as the base for the generated
/// product descriptors.
///
/// Raises \c NSInvalidArgumentException if:
///   \c productAxes does not contain any base product axes.
///   \c productAxes has duplicate axes.
///   \c baseProductValues does not provide values for all base product axes in \c productAxes.
- (instancetype)initWithProductAxes:(NSArray<id<SPXProductAxis>> *)productAxes
                            version:(NSString *)version prefix:(NSString *)prefix
    baseProducts:(NSArray<NSArray<SPXBaseProductAxisValue *> *> *)baseProductValues
    NS_DESIGNATED_INITIALIZER;

/// Product matrix version.
@property (readonly, nonatomic) NSString *version;

/// Perfix for product identifiers.
@property (readonly, nonatomic) NSString *prefix;

/// Axes of the product matrix.
@property (readonly, nonatomic) NSArray<id<SPXProductAxis>> *productAxes;

/// Base products values to create products from.
@property (readonly, nonatomic) NSArray<NSArray<SPXBaseProductAxisValue *> *> *baseProductValues;

/// Returns the products matching the \c baseProductValues, with \c promotion applied on the
/// matching product. If \c promotion is \c nil, the default value for every benefit axis will be
/// applied. Returns \c nil if an error occures. In this case \c error will contain the relevant
/// error. The order of the returned products is the same as the \c baseProductValues parameter in
/// the initializer.
///
/// This method can fail with the following errors:
///   SPXErrorCodePromotionExpired - When the promotion's \c expiryDate has passed.
///   SPXErrorCodeInvalidCoupon - When a coupon has multiple values for the same benefit axis.
///   SPXErrorCodeConflictingCouponsInPromotion - When \c promotion contains conflicting coupons -
///       a coupon with base product values that are subset of another coupons conflicts with that
///       second coupon.
- (nullable NSArray<SPXProductDescriptor *> *)
    productDescriptorsWithPromotion:(nullable SPXPromotion *)promotion
                          withError:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
