// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXPromotion.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSDateFormatter+Formatters.h>
#import <LTKit/NSDictionary+Functional.h>

#import "NSError+Shopix.h"
#import "SPXProductAxis.h"

NS_ASSUME_NONNULL_BEGIN

static LTBidirectionalMap<NSString *, Class> *PTNNameToProductAxis() {
  static auto nameToProductAxis = [LTBidirectionalMap<NSString *, Class> mapWithDictionary:@{
    @"DiscountLevel": [SPXBenefitProductAxisDiscountLevel class],
    @"FreeTrialDuration": [SPXBenefitProductAxisFreeTrialDuration class],
    @"SubscriptionPeriod": [SPXBaseProductAxisSubscriptionPeriod class]
  }];
  return nameToProductAxis;
}

static NSDictionary<NSString *, NSString *> *
    SPXAxisValueToDictionary(id<SPXProductAxisValue> value) {
  return @{
    @"axis": nn([PTNNameToProductAxis() keyForObject:[value.axis class]]),
    @"value": value.value
  };
}

static id<SPXProductAxisValue> _Nullable SPXAxisValueFromDictionary(
    NSDictionary<NSString *, NSString *> *dict, Protocol *axis, Class axisValueClass) {
  LTParameterAssert([axisValueClass conformsToProtocol:@protocol(SPXProductAxisValue)], @"Given "
                    "axis value must conform to SPXProductAxisValue");
  NSString * _Nullable axisClassName = dict[@"axis"];
  if (![axisClassName isKindOfClass:[NSString class]]) {
    LogError(@"Trying to deserialize axis without axis key or with non-string value");
    return nil;
  }
  auto _Nullable axisClass = PTNNameToProductAxis()[axisClassName];
  if (!axisClass) {
    LogError(@"Trying to deserialize axis with non-existing axis class %@", axisClassName);
    return nil;
  }
  if (![axisClass conformsToProtocol:axis]) {
    LogError(@"Trying to deserialize axis with class %@ that does not conform to %@", axisClass,
             axis);
    return nil;
  }
  NSString * _Nullable value = dict[@"value"];
  if (![value isKindOfClass:[NSString class]]) {
    LogError(@"Trying to deserialize axis value without value key or with non-string value");
    return nil;
  }
  id<SPXProductAxisValue> axisValue = [axisValueClass
                                       axisValueWithValue:nn(value)
                                       andAxis:[[nn(axisClass) alloc] init]];
  if (![axisValue.axis.values containsObject:axisValue]) {
    LogError(@"Trying to deserialize value %@ that does not exist for axis %@", value,
             axisValue.axis);
    return nil;
  }
  return axisValue;
}

/// Returns \c YES if \c dictionary has keys for all the properties of \c modelClass, and all the
/// value in \c dictionary are not <tt>[NSNull null]</tt>.
///
/// @note \c modelClass must a \c MTLModel.
BOOL SPXVerifyDictionaryHasAllPropertiesForClass(NSDictionary *dictionary, Class modelClass,
                                                 NSError **error) {
  if (![[modelClass propertyKeys] isEqualToSet:[NSSet setWithArray:dictionary.allKeys]]) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                             description:@"Missing property in dictionary %@", dictionary];
    }
    return NO;
  }

  if ([dictionary.allValues containsObject:[NSNull null]]) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                             description:@"Null value in dictionary %@", dictionary];
    }
    return NO;
  }

  return YES;
}

/// Adds the tryMap method.
@interface NSArray<ObjectType> (TryMap)

/// Callback block used with \c lt_tryMap: method.
typedef id _Nullable(^SPXArrayTryMapBlock)(ObjectType _Nonnull object);

/// Returns a new array with the results of calling the provided \c block on every element in this
/// array. If \c block returns \c nil, \c nil is returned.
///
/// @see [NSArray lt_map:]
- (nullable NSArray *)spx_tryMap:(NS_NOESCAPE SPXArrayTryMapBlock)block;

@end

@implementation NSArray (TryMap)

- (nullable NSArray *)spx_tryMap:(SPXArrayTryMapBlock)block {
  LTParameterAssert(block);

  NSMutableArray *mapped = [NSMutableArray arrayWithCapacity:self.count];
  for (id object in self) {
    id value = block(object);
    if (!value) {
      return nil;
    }
    [mapped addObject:value];
  }
  return mapped;
}

@end

@implementation SPXCoupon

- (instancetype)initWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                            benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues {
  if (self = [super init]) {
    _baseProductValues = baseProductValues;
    _benefitValues = benefitValues;
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                             error:(NSError *__autoreleasing *)error {
  if (!SPXVerifyDictionaryHasAllPropertiesForClass(dictionary, [self class], error)) {
    return nil;
  }

  return [super initWithDictionary:dictionary error:error];
}

+ (instancetype)couponWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                              benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues {
  return [[SPXCoupon alloc] initWithBaseProductValues:baseProductValues
                                        benefitValues:benefitValues];
}

+ (NSValueTransformer *)baseProductValuesJSONTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSArray<SPXBaseProductAxisValue *> *(NSArray<NSDictionary *> *array) {
    return [array spx_tryMap:^SPXBaseProductAxisValue * _Nullable(NSDictionary *dict) {
      return SPXAxisValueFromDictionary(dict, @protocol(SPXBaseProductAxis),
                                        [SPXBaseProductAxisValue class]);
    }];
  } reverseBlock:^NSArray<NSString *> *(NSArray<SPXBaseProductAxisValue *> *values) {
    return [values lt_map:^NSDictionary *(SPXBaseProductAxisValue *value) {
      return SPXAxisValueToDictionary(value);
    }];
  }];
}

+ (NSValueTransformer *)benefitValuesJSONTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSArray<SPXBenefitAxisValue *> *(NSArray<NSString *> *array) {
    return [array spx_tryMap:^SPXBenefitAxisValue *(NSDictionary *dict) {
      return SPXAxisValueFromDictionary(dict, @protocol(SPXBenefitAxis),
                                        [SPXBenefitAxisValue class]);
    }];
  } reverseBlock:^NSArray<NSString *> *(NSArray<SPXBenefitAxisValue *> *values) {
    return [values lt_map:^NSDictionary *(SPXBenefitAxisValue *value) {
      return SPXAxisValueToDictionary(value);
    }];
  }];
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(SPXCoupon, baseProductValues): @"baseProductValues",
    @instanceKeypath(SPXCoupon, benefitValues): @"benefitValues"
  };
}

@end

@implementation SPXPromotion

- (instancetype)initWithName:(NSString *)name coupons:(NSArray<SPXCoupon *> *)coupons
                  expiryDate:(NSDate *)expiryDate {
  if (self = [super init]) {
    _name = name;
    _coupons = coupons;
    _expiryDate = expiryDate;
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                             error:(NSError *__autoreleasing *)error {
  if (!SPXVerifyDictionaryHasAllPropertiesForClass(dictionary, [self class], error)) {
    return nil;
  }

  return [super initWithDictionary:dictionary error:error];
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(SPXPromotion, name): @"name",
    @instanceKeypath(SPXPromotion, coupons): @"coupons",
    @instanceKeypath(SPXPromotion, expiryDate): @"expiryDate"
  };
}

+ (NSValueTransformer *)couponsJSONTransformer {
  NSValueTransformer *dictionaryTransformer =
      [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[SPXCoupon class]];

  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^NSArray<SPXCoupon *> *(NSArray *array) {
    if (![array isKindOfClass:[NSArray class]]) {
      LogError(@"Expected an NSArray, got: %@", array);
      return nil;
    }

    return [array spx_tryMap:^SPXCoupon * _Nullable(NSDictionary *dictionary) {
      if (![dictionary isKindOfClass:[NSDictionary class]]) {
        LogError(@"Expected a dictionary, got: %@", dictionary);
        return nil;
      }

      return [dictionaryTransformer transformedValue:dictionary];
    }];
  } reverseBlock:^NSArray *(NSArray<SPXCoupon *> *models) {
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
    for (id model in models) {
      if (model == [NSNull null]) {
        [dictionaries addObject:[NSNull null]];
        continue;
      }
      NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model];
      if (!dict) {
        continue;
      }
      [dictionaries addObject:dict];
    }
    return dictionaries;
  }];
}

+ (NSValueTransformer *)expiryDateJSONTransformer {
  NSDateFormatter *formatter = [[self class] dateFormatter];
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSDate * _Nullable(NSString *string) {
    if (![string isKindOfClass:[NSString class]]) {
      LogError(@"Expected a NSString, got: %@", [string class]);
      return nil;
    }
    NSDate * _Nullable result = [formatter dateFromString:string];
    if (!result) {
      LogError(@"Given string %@ is not according to expected format", string);
      return nil;
    }
    return result;
  } reverseBlock:^NSString *(NSDate *date) {
    return [formatter stringFromDate:date];
  }];
}

+ (NSDateFormatter *)dateFormatter {
  static auto *dateFormatter = [NSDateFormatter lt_UTCDateFormatter];
  return dateFormatter;
}

@end

NS_ASSUME_NONNULL_END
