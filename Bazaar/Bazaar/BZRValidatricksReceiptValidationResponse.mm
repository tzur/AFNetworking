// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidationResponse.h"

#import "BZRValidatricksReceiptModel.h"
#import "NSValueTransformer+Validatricks.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRValidatricksReceiptValidationResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptValidationResponse, isValid): @"valid",
    @instanceKeypath(BZRReceiptValidationResponse, error): @"reason",
    @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): @"currentDateTime",
    @instanceKeypath(BZRReceiptValidationResponse, receipt): @"receipt",
  };
}

+ (NSValueTransformer *)errorJSONTransformer {
  return [NSValueTransformer bzr_validatricksErrorValueTransformer];
}

+ (NSValueTransformer *)validationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
}

+ (NSValueTransformer *)receiptJSONTransformer {
  return [NSValueTransformer
          mtl_JSONDictionaryTransformerWithModelClass:[BZRValidatricksReceiptInfo class]];
}

@end

NS_ASSUME_NONNULL_END
