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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)errorJSONTransformer {
  return [NSValueTransformer bzr_enumNameTransformerForClass:[BZRReceiptValidationError class]];
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

@end

NS_ASSUME_NONNULL_END
