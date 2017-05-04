// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSScanner+Math.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSScanner (Math)

- (BOOL)lt_scanFloat:(float *)result {
  if ([self scanString:@"nan" intoString:NULL]) {
    if (result) {
      *result = NAN;
    }
    return YES;
  } else if ([self scanString:@"inf" intoString:NULL]) {
    if (result) {
      *result = INFINITY;
    }
    return YES;
  } else if ([self scanString:@"-inf" intoString:NULL]) {
    if (result) {
      *result = -INFINITY;
    }
    return YES;
  }

  return [self scanFloat:result];
}

- (BOOL)lt_scanCommaSeparatedFloats:(float *)values length:(size_t)length {
  for (size_t i = 0; i < length; ++i) {
    if (![self lt_scanFloat:(values + i)]) {
      return NO;
    }
    if (i < length - 1) {
      if (![self scanString:@"," intoString:nil]) {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)lt_scanFloatVector:(float *)values length:(size_t)length {
  if (![self scanString:@"{" intoString:nil]) {
    return NO;
  }
  if (![self lt_scanCommaSeparatedFloats:values length:length]) {
    return NO;
  }
  return [self scanString:@"}" intoString:nil];
}

- (BOOL)lt_scanFloatMatrix:(float *)values rows:(size_t)rows cols:(size_t)cols {
  if (![self scanString:@"{" intoString:nil]) {
    return NO;
  }

  for (size_t i = 0; i < rows; ++i) {
    if (![self lt_scanFloatVector:(values + i * cols) length:cols]) {
      return NO;
    }
    if (i < rows - 1 && ![self scanString:@"," intoString:nil]) {
      return NO;
    }
  }

  if (![self scanString:@"}" intoString:nil]) {
    return NO;
  }
  return [self isAtEnd];
}

@end

NS_ASSUME_NONNULL_END
