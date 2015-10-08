// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSNumber+CGFloat.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSNumber (CGFloat)

+ (NSNumber *)numberWithCGFloat:(CGFloat)value {
#if CGFLOAT_IS_DOUBLE
  return [NSNumber numberWithDouble:value];
#else
  return [NSNumber numberWithFloat:value];
#endif
}

- (instancetype)initWithCGFloat:(CGFloat)value {
#if CGFLOAT_IS_DOUBLE
  return [self initWithDouble:value];
#else
  return [self initWithFloat:value];
#endif
}

- (CGFloat)CGFloatValue {
#if CGFLOAT_IS_DOUBLE
  return [self doubleValue];
#else
  return [self floatValue];
#endif
}

@end

NS_ASSUME_NONNULL_END
