// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Category for boxing and unboxing \c CGFloat.
@interface NSNumber (CGFloat)

/// Creates and returns an \c NSNumber object containing a given value, treating it as a \c CGFloat.
+ (NSNumber *)numberWithCGFloat:(CGFloat)value;

/// Returns an \c NSNumber object initialized to contain value, treated as a \c CGFloat.
- (instancetype)initWithCGFloat:(CGFloat)value;

/// Returns the receiver's value as a \c CGFloat.
- (CGFloat)CGFloatValue;

@end
