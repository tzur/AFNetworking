// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSValueTransformer+Bazaar.h"

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptValidationError.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSValueTransformer (Bazaar)

+ (NSValueTransformer *)bzr_timeIntervalSince1970ValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSDate * _Nullable(NSNumber * _Nullable timeInterval) {
            return timeInterval ?
                [NSDate dateWithTimeIntervalSince1970:[timeInterval doubleValue]] : nil;
          } reverseBlock:^NSNumber * _Nullable(NSDate * _Nullable dateTime) {
            return dateTime ? @(dateTime.timeIntervalSince1970) : nil;
          }];
}

+ (NSValueTransformer *)bzr_millisecondsDateTimeValueTransformer {
  static const double kMilliSecondsPerSecond = 1000;

  NSValueTransformer *transformer =
      [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSDate * _Nullable(NSNumber * _Nullable timeInterval) {
    return timeInterval ?
        [transformer transformedValue:@([timeInterval doubleValue] / kMilliSecondsPerSecond)] : nil;
  } reverseBlock:^NSNumber * _Nullable(NSDate * _Nullable dateTime) {
    NSNumber *timeInterval = [transformer reverseTransformedValue:dateTime];
    return timeInterval ? @([timeInterval doubleValue] * kMilliSecondsPerSecond) : nil;
  }];
}

+ (NSValueTransformer *)bzr_validatricksErrorValueTransformer {
  static NSDictionary * validatricksFailureReasonToErrorCodeMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    validatricksFailureReasonToErrorCodeMap = @{
      @"invalidJson": $(BZRReceiptValidationErrorMalformedReceiptData),
      @"malformedData": $(BZRReceiptValidationErrorMalformedReceiptData),
      @"notAuthenticated": $(BZRReceiptValidationErrorReceiptIsNotAuthentic),
      @"unexpectedBundle": $(BZRReceiptValidationErrorBundleIDMismatch),
      @"mismatchingDevice": $(BZRReceiptValidationErrorDeviceIDMismatch),
      @"testReceiptInProd": $(BZRReceiptValidationErrorEnvironmentMismatch),
      @"prodReceiptInTest": $(BZRReceiptValidationErrorEnvironmentMismatch),
      @"missingReceipt": $(BZRReceiptValidationErrorMissingReceipt)
    };
  });

  return [MTLValueTransformer
          transformerWithBlock:^BZRReceiptValidationError * _Nullable(NSString * _Nullable reason) {
            if (!reason) {
              return nil;
            }

            return validatricksFailureReasonToErrorCodeMap[reason] ?:
                $(BZRReceiptValidationErrorUnknown);
          }];
}

+ (NSValueTransformer *)bzr_validatricksReceiptEnvironmentValueTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"sandbox": $(BZRReceiptEnvironmentSandbox),
    @"production": $(BZRReceiptEnvironmentProduction)
  }];
}

+ (NSValueTransformer *)bzr_enumNameTransformerForClass:(Class)enumClass {
  LTParameterAssert([enumClass conformsToProtocol:@protocol(LTEnum)], @"Given class %@ doesn't "
                    "conform to the LTEnum protocol", enumClass);

  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
      ^id<LTEnum> _Nullable(NSString * _Nullable name) {
        if (!name || ![enumClass fieldNamesToValues][name]) {
          return nil;
        }

        return [[enumClass alloc] initWithName:name];
      } reverseBlock:^NSString * _Nullable(id<LTEnum> _Nullable enumObject) {
        return enumObject.name;
      }];
}

@end

NS_ASSUME_NONNULL_END
