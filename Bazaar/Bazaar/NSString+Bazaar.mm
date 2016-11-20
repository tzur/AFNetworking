// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (Bazaar)

NSString * const kVariant = @".Variant.";

- (NSString *)bzr_variantWithSuffix:(NSString *)variantSuffix {
  return [self stringByAppendingFormat:@"%@%@", kVariant, variantSuffix];
}

- (NSString *)bzr_baseProductIdentifier {
  NSRange variantLocation = [self rangeOfString:kVariant];
  if (variantLocation.location == NSNotFound) {
    return self;
  }
  return [self substringToIndex:variantLocation.location];
}

@end

NS_ASSUME_NONNULL_END
