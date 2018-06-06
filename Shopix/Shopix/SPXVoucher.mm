// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXVoucher.h"

#import <CommonCrypto/CommonCrypto.h>
#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSData+Base64.h>
#import <LTKit/NSData+Compression.h>
#import <LTKit/NSData+Encryption.h>
#import <LTKit/NSData+Hashing.h>
#import <LTKit/NSDateFormatter+Formatters.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSString+Hashing.h>
#import <random>

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

- (nullable NSArray *)spx_tryMap:(NS_NOESCAPE SPXArrayTryMapBlock)block {
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

@implementation SPXVoucher

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

- (NSData *)randomDataWithLength:(NSUInteger)length {
  auto randomData = [NSMutableData dataWithLength:length];
  arc4random_buf(randomData.mutableBytes, length);
  return randomData;
}

- (nullable NSString *)serializeAndSignWithKey:(NSString *)key
                                         error:(NSError *__autoreleasing *)error {
#if defined(DEBUG) && DEBUG
  auto serializedVoucher = [MTLJSONAdapter JSONDictionaryFromModel:self];
  auto _Nullable jsonData = [NSJSONSerialization dataWithJSONObject:serializedVoucher options:0
                                                              error:nil];
  NSError *underlyingError;
  auto _Nullable compressed = [nn(jsonData) lt_compressWithCompressionType:LTCompressionTypeZLIB
                                                                     error:&underlyingError];
  if (!compressed) {
    if (error) {
      *error = [NSError spx_errorWithCode:SPXErrorCodeInvalidCoupon associatedVoucher:self
                          underlyingError:underlyingError];
    }
    return nil;
  }

  auto keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
  // Hashing with MD5 always return 16-byte buffer, which can be used as key for AES128.
  auto encrypted = [compressed lt_encryptWithKey:[keyData lt_MD5]
                                              iv:[self randomDataWithLength:16]
                                           error:&underlyingError];

  if (!encrypted) {
    if (error) {
      *error = [NSError spx_errorWithCode:SPXErrorCodeInvalidCoupon associatedVoucher:self
                          underlyingError:underlyingError];
    }
    return nil;
  }
  auto signature = [encrypted lt_HMACSHA256WithKey:keyData];

  NSMutableData *data = [signature mutableCopy];
  [data appendData:encrypted];
  return [data lt_urlSafeBase64];
#else
  // The real implementation of the method is not in release mode because then users will be able to
  // create signed vouchers.
  LogError(@"%@ called in release mode with key %@ and error %p", NSStringFromSelector(_cmd), key,
           error);
  return nil;
#endif
}

+ (nullable instancetype)voucherWithSerializedString:(NSString *)string key:(NSString *)key
                                               error:(NSError *__autoreleasing *)error {
  auto _Nullable data = [[NSData alloc] initWithURLSafeBase64EncodedString:string];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed description:@"Unable to "
                "decode URL-safe-base64 from given serialized voucher %@", string];
    }
    return nil;
  }
  static NSUInteger kSignatureLength = 32;
  if (data.length <= kSignatureLength) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed description:@"Given "
                "serialized voucher %@ is too short for deserialization", string];
    }
    return nil;
  }

  auto _Nullable signature = [data subdataWithRange:NSMakeRange(0, kSignatureLength)];
  auto _Nullable encrypted = [data subdataWithRange:NSMakeRange(kSignatureLength,
                                                                data.length - kSignatureLength)];
  auto keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
  auto localSignature = [nn(encrypted) lt_HMACSHA256WithKey:keyData];
  if (![localSignature isEqual:nn(signature)]) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeSignatureValidationFailed description:
                @"Signature %@ does match does not match encrypted voucher %@", signature,
                localSignature];
    }
    return nil;
  }

  NSError *underlyingError;
  auto _Nullable decrypted = [encrypted lt_decryptWithKey:[keyData lt_MD5] error:&underlyingError];
  if (!decrypted) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                         underlyingError:underlyingError description:@"Unable to decrypt buffer %@",
                encrypted];
    }
    return nil;
  }

  auto _Nullable decompressed = [decrypted lt_decompressWithCompressionType:LTCompressionTypeZLIB
                                                                      error:&underlyingError];
  if (!decompressed) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                         underlyingError:underlyingError description:@"Unable to decompress buffer "
                "%@", decrypted];
    }
    return nil;
  }

  id jsonDict = [NSJSONSerialization JSONObjectWithData:nn(decompressed) options:0
                                                  error:&underlyingError];
  if (!jsonDict) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                         underlyingError:underlyingError
                             description:@"Unable to deserialize voucher %@", decompressed];
    }
    return nil;
  }

  if (![jsonDict isKindOfClass:[NSDictionary class]]) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed description:@"Expected "
                "deserialize voucher to be dictionary, but got %@", jsonDict];
    }
    return nil;
  }

  SPXVoucher * _Nullable voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class
                                             fromJSONDictionary:jsonDict
                                                          error:&underlyingError];
  if (!voucher) {
    if (error) {
      *error = [NSError lt_errorWithCode:SPXErrorCodeDeserializationFailed
                         underlyingError:underlyingError
                             description:@"Unable to deserialize voucher %@", jsonDict];
    }
    return nil;
  }

  return nn(voucher);
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(SPXVoucher, name): @"name",
    @instanceKeypath(SPXVoucher, coupons): @"coupons",
    @instanceKeypath(SPXVoucher, expiryDate): @"expiryDate"
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
