// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXProductDescriptorsFactory.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSSet+Functional.h>

#import "NSError+Shopix.h"
#import "SPXProductAxis.h"
#import "SPXProductDescriptor.h"
#import "SPXPromotion.h"

NS_ASSUME_NONNULL_BEGIN

/// Category that enables the creation of \c SPXProductDescriptor objects from
/// \c SPXProductAxisValue objects.
@interface SPXProductDescriptor (ProductDescriptorsFactory)

/// Initializes with the \c values for the axis of the products matrix. \c values are used to
/// create the product identifier and prepended by \c prefix and \c version. \c baseProductValues
/// and \c benefitValues are taken from \c values according to their class.
- (instancetype)initWithProductAxisValues:(NSArray<id<SPXProductAxisValue>> *)values
                                  version:(NSString *)version prefix:(NSString *)prefix;

@end

@implementation SPXProductDescriptor (ProductDescriptorsFactory)

- (instancetype)initWithProductAxisValues:(NSArray<id<SPXProductAxisValue>> *)values
                                  version:(NSString *)version prefix:(NSString *)prefix {
  auto baseProductValues = [[values lt_filter:^BOOL(id<SPXProductAxisValue> axisValue) {
    return [axisValue.axis conformsToProtocol:@protocol(SPXBaseProductAxis)];
  }] lt_set];
  auto benefitValues = [[values lt_filter:^BOOL(id<SPXProductAxisValue> axisValue) {
    return [axisValue.axis conformsToProtocol:@protocol(SPXBenefitAxis)];
  }] lt_set];
  auto identifierComponents = [values lt_map:^NSString *(id<SPXProductAxisValue> axisValue) {
    return axisValue.value;
  }];
  auto identifier = [[@[prefix, version] arrayByAddingObjectsFromArray:identifierComponents]
                     componentsJoinedByString:@"."];
  return [self initWithIdentifier:identifier baseProductValues:baseProductValues
                    benefitValues:benefitValues];
}

@end

@interface NSSet<ObjectType> (ProductDescriptorsFactory)

/// Returns the intersecting set of the receiver and \c other.
- (NSSet<ObjectType> *)setByIntersectingWithSet:(NSSet<ObjectType> *)other;

/// Maps a set of \c SPXProductAxisValue objects to a set of their axes.
- (NSSet<id<SPXProductAxis>> *)valuesAxes;

@end

@implementation NSSet (ProductDescriptorsFactory)

- (NSSet *)setByIntersectingWithSet:(NSSet *)other {
  auto *mutableSelf = [NSMutableSet setWithSet:self];
  [mutableSelf intersectSet:other];
  return mutableSelf;
}

- (NSSet<id<SPXProductAxis>> *)valuesAxes {
  return [self lt_map:^id<SPXProductAxis> (id<SPXProductAxisValue> value) {
    return value.axis;
  }];
}

@end

/// Catergory enabling easy access to axis values by axis.
@interface NSArray<ObjectType> (ProductDescriptorsFactory)

/// Returns the first \c SPXBaseProductAxisValue object with \c axis as its axis or \c nil if no
/// such value exist.
- (nullable id<SPXProductAxisValue>)firstAxisValueWithAxis:(id<SPXProductAxis>)axis;

/// Returns an array of all \c SPXBaseProductAxisValue objects with \c axis as its axis. Empty array
/// is returned if no such value exist.
- (NSArray<id<SPXProductAxisValue>> *)allAxisValueWithAxis:(id<SPXProductAxis>)axis;

/// Maps an array of \c SPXProductAxisValue objects to a set of their axes.
- (NSArray<id<SPXProductAxis>> *)valuesAxes;

@end

@implementation NSArray (ProductDescriptorsFactory)

- (nullable id<SPXProductAxisValue>)firstAxisValueWithAxis:(id<SPXProductAxis>)axis {
  return [self lt_find:^BOOL(id<SPXProductAxisValue> value) {
    return [value.axis isEqual:axis];
  }];
}

- (NSArray<id<SPXProductAxisValue>> *)allAxisValueWithAxis:(id<SPXProductAxis>)axis {
  return [self lt_filter:^BOOL (id<SPXProductAxisValue> value) {
    return [value.axis isEqual:axis];
  }];
}

- (NSArray<id<SPXProductAxis>> *)valuesAxes {
  return [self lt_map:^id<SPXProductAxis> (id<SPXProductAxisValue> value) {
    return value.axis;
  }];
}

@end

/// Category for easy access to coupons with matching base product values.
@interface SPXPromotion (ProductDescriptorsFactory)

/// Returns the first \c SPXCoupon that matches the given \c values. A coupon matches a value if
/// all the base axes appearing in the coupon have matching values in both the coupon and the base
/// product values.
///
/// @example The products matrix has 2 base products axes, A with values [X, Y] and B with values
/// [U, V]. A base product P has values { A: X, B: U }. A coupon with base product values
/// { A: X, B: U } will match P, as both axes have the same values (X and U) in both P and the
/// coupon.
///
/// @example Coupon with base product values { A: X, A: Y }. Only axis A is used, and for that axis
/// the same value exists in both the coupon and in P, so the coupon matches P.
///
/// @example Coupon with base prodcut values { A: X, B: V }. Both A and B axes are used. For axis A
/// the same value exist in both the coupon and P. But for axis B, there is no value in both the
/// coupon and P, so the coupon does not match P.
- (nullable SPXCoupon *)couponForBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)values;

@end

@implementation SPXPromotion (ProductDescriptorsFactory)

- (nullable SPXCoupon *)couponForBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)values {
  return [self.coupons lt_find:^BOOL(SPXCoupon *coupon) {
    auto *couponBaseAxes = [[coupon.baseProductValues valuesAxes] lt_set];
    auto *intersectAxes = [[[coupon.baseProductValues lt_set]
                            setByIntersectingWithSet:[values lt_set]] valuesAxes];
    return ([intersectAxes isEqual:couponBaseAxes]);
  }];
}

@end

@implementation SPXProductDescriptorsFactory

- (instancetype)initWithProductAxes:(NSArray<id<SPXProductAxis>> *)productAxes
                            version:(NSString *)version prefix:(NSString *)prefix
    baseProducts:(NSArray<NSArray<SPXBaseProductAxisValue *> *> *)baseProductValues {
  if (self = [super init]) {
    [self validateBaseProductValues:baseProductValues withProductAxes:productAxes];
    _productAxes = productAxes;
    _version = version;
    _prefix = prefix;
    _baseProductValues = baseProductValues;
  }
  return self;
}

- (void)validateBaseProductValues:(NSArray<NSArray<SPXBaseProductAxisValue *> *> *)baseProductValues
                  withProductAxes:(NSArray<id<SPXProductAxis>> *)productAxes {
  LTParameterAssert([self verifyBaseProductAxisExist:productAxes], @"Product axes %@ does not "
                    "contain base product axis", productAxes);
  LTParameterAssert([self verifyNoDuplicates:productAxes], @"Duplicate axis in axes %@",
                    productAxes);
  auto baseProductAxes = [productAxes lt_filter:^BOOL(id<SPXBaseProductAxis> axis) {
    return [axis conformsToProtocol:@protocol(SPXBaseProductAxis)];
  }];
  for (NSArray<SPXBaseProductAxisValue *> *productValues in baseProductValues) {
    auto productBaseProductAxes = [productValues valuesAxes];
    LTParameterAssert([productBaseProductAxes isEqual:baseProductAxes], @"Base product axes %@ "
                      "does not match given product axes %@", productBaseProductAxes,
                      baseProductAxes);
  }
}

- (BOOL)verifyBaseProductAxisExist:(NSArray<id<SPXProductAxis>> *)productAxes {
  return [productAxes lt_find:^BOOL(id<SPXProductAxis> axis) {
    return [axis conformsToProtocol:@protocol(SPXBaseProductAxis)];
  }] != nil;
}

- (BOOL)verifyNoDuplicates:(NSArray *)array {
  return [array lt_set].count == array.count;
}

- (nullable NSArray<SPXProductDescriptor *> *)
    productDescriptorsWithPromotion:(nullable SPXPromotion *)promotion
                          withError:(NSError *__autoreleasing *)error {
  if (![self validatePromotion:promotion error:error]) {
    return nil;
  }

  return [self.baseProductValues lt_map:
          ^SPXProductDescriptor *(NSArray<SPXBaseProductAxisValue *> *baseValues) {
    auto _Nullable coupon = [promotion couponForBaseProductValues:baseValues];

    NSArray<id<SPXProductAxisValue>> *productValues =
        [self.productAxes lt_map:^id<SPXProductAxisValue> (id<SPXProductAxis> axis) {
          if ([axis conformsToProtocol:@protocol(SPXBaseProductAxis)]) {
            return nn([baseValues firstAxisValueWithAxis:axis]);
          } else if ([axis conformsToProtocol:@protocol(SPXBenefitAxis)]) {
            return
                nn<id<SPXProductAxisValue>> ([coupon.benefitValues firstAxisValueWithAxis:axis],
                                             ((id<SPXBenefitAxis>)axis).defaultValue);
          } else {
            LTAssert(NO, @"Unknown product axis class %@", axis);
          }
        }];
    return [[SPXProductDescriptor alloc] initWithProductAxisValues:productValues
                                                           version:self.version prefix:self.prefix];
  }];
}

- (BOOL)validatePromotion:(nullable SPXPromotion *)promotion
                    error:(NSError * __autoreleasing *)error {
  if (!promotion) {
    return YES;
  }

  if ([[promotion.expiryDate earlierDate:[NSDate date]] isEqual:promotion.expiryDate]) {
    if (error) {
      *error = [NSError spx_errorWithCode:SPXErrorCodePromotionExpired
                      associatedPromotion:promotion];
    }
    return NO;
  }

  for (SPXCoupon *coupon in promotion.coupons) {
    if (![self verifyNoDuplicates:[coupon.benefitValues valuesAxes]]) {
      if (error) {
        *error = [NSError spx_errorWithCode:SPXErrorCodeInvalidCoupon associatedPromotion:promotion
                           associatedCoupon:coupon];
      }
      return NO;
    }

    if (![self verifyNoConflictWithCoupon:coupon inPromotion:promotion error:error]) {
      return NO;
    }
  }

  return YES;
}

- (BOOL)verifyNoConflictWithCoupon:(SPXCoupon *)coupon inPromotion:(SPXPromotion *)promotion
                             error:(NSError *__autoreleasing *)error {
  for (SPXCoupon *otherCoupon in promotion.coupons) {
    if (coupon == otherCoupon) {
      continue;
    }
    auto couponBaseAxes = [[coupon.baseProductValues valuesAxes] lt_set];
    auto otherCouponBaseAxes = [[otherCoupon.baseProductValues valuesAxes] lt_set];
    auto intersectAxes = [[[coupon.baseProductValues lt_set]
                           setByIntersectingWithSet:[otherCoupon.baseProductValues lt_set]]
                          valuesAxes];
    if (std::min(couponBaseAxes.count, otherCouponBaseAxes.count) == intersectAxes.count) {
      if (error) {
        *error = [NSError spx_errorWithCode:SPXErrorCodeConflictingCoupons
                        associatedPromotion:promotion associatedCoupon:coupon];
      }
      return NO;
    }
  }
  return YES;
}

- (nullable NSArray<SPXProductDescriptor *> *)
    productDescriptorsWithCoupons:(nullable NSArray<SPXCoupon *>*)coupons
                        withError:(NSError *__autoreleasing *)error {
  auto promotion = [[SPXPromotion alloc] initWithName:@"__SPXOnlyCoupons__" coupons:coupons
                                           expiryDate:[NSDate distantFuture]];
  return [self productDescriptorsWithPromotion:promotion withError:error];
}

@end

NS_ASSUME_NONNULL_END
