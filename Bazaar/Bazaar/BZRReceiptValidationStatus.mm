// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationStatus.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "NSValueTransformer+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationStatus

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptValidationStatus, error),
      @instanceKeypath(BZRReceiptValidationStatus, receipt),
    ]];
  });

  return optionalPropertyKeys;
}

+ (NSDictionary<NSString *, id> *)defaultPropertyValues {
  static NSDictionary<NSString *, id> *defaultPropertyValues;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultPropertyValues = @{
      @instanceKeypath(BZRReceiptValidationStatus, requestId): @""
    };
  });

  return defaultPropertyValues;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptValidationStatus, receipt): @"receipt",
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @"valid",
    @instanceKeypath(BZRReceiptValidationStatus, error): @"reason",
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): @"currentDateTime",
    @instanceKeypath(BZRReceiptValidationStatus, requestId): @"requestId"
  };
}

+ (NSValueTransformer *)errorJSONTransformer {
  return [NSValueTransformer bzr_validatricksErrorValueTransformer];
}

+ (NSValueTransformer *)validationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)receiptJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[BZRReceiptInfo class]];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (BOOL)validate:(NSError *__autoreleasing *)error {
  if (self.isValid && !self.receipt) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Receipt validation status indicates that the receipt "
                                          "is valid but receipt information is missing"];
    }
    return NO;
  }

  if (!self.isValid && !self.error) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Receipt validation status indicates that the receipt "
                                          "is invalid but validation error is missing"];
    }
    return NO;
  }

  return YES;
}

@end

NS_ASSUME_NONNULL_END
