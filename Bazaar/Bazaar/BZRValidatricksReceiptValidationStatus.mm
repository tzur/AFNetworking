// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidationStatus.h"

#import "BZRValidatricksReceiptModel.h"
#import "NSValueTransformer+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRValidatricksReceiptValidationStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[BZRReceiptValidationStatus JSONKeyPathsByPropertyKey]
          mtl_dictionaryByAddingEntriesFromDictionary:@{
            @instanceKeypath(BZRReceiptValidationStatus, isValid): @"valid",
            @instanceKeypath(BZRReceiptValidationStatus, error): @"reason",
            @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): @"currentDateTime",
            @instanceKeypath(BZRValidatricksReceiptValidationStatus, requestId): @"requestId"
          }];
}

+ (NSDictionary<NSString *, id> *)defaultPropertyValues {
  static NSDictionary<NSString *, id> *defaultPropertyValues;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultPropertyValues = @{
      @instanceKeypath(BZRValidatricksReceiptValidationStatus, requestId): @""
    };
  });

  return defaultPropertyValues;
}

+ (NSValueTransformer *)errorJSONTransformer {
  return [NSValueTransformer bzr_validatricksErrorValueTransformer];
}

+ (NSValueTransformer *)receiptJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRValidatricksReceiptInfo class]];
}

@end

NS_ASSUME_NONNULL_END
