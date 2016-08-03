// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidationStatus.h"

#import "BZRValidatricksReceiptModel.h"
#import "NSValueTransformer+Validatricks.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRValidatricksReceiptValidationStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @"valid",
    @instanceKeypath(BZRReceiptValidationStatus, error): @"reason",
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): @"currentDateTime",
    @instanceKeypath(BZRReceiptValidationStatus, receipt): @"receipt",
  };
}

+ (NSValueTransformer *)errorJSONTransformer {
  return [NSValueTransformer bzr_validatricksErrorValueTransformer];
}

+ (NSValueTransformer *)validationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_validatricksDateTimeValueTransformer];
}

+ (NSValueTransformer *)receiptJSONTransformer {
  return [NSValueTransformer
          mtl_JSONDictionaryTransformerWithModelClass:[BZRValidatricksReceiptInfo class]];
}

@end

NS_ASSUME_NONNULL_END
