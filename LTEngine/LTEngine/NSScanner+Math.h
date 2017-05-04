// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

/// Category adding the functionality to scan various algebraic structures e.g. 2D matrices,
/// vectors, comma separated values and floating point values.
@interface NSScanner (Math)

/// Scans for a float value, writes the found value into the given \c result reference. This method
/// correctly handles non-numeric values such as \c nan, \c inf and \c -inf. Returns \c YES if the
/// a valid floating-point representation was found, otherwise \c NO.
- (BOOL)lt_scanFloat:(float *)result;

/// Scans \c length floating point elements and stores them in the given \c values array in order
/// of appearance. \c values assumed to be pre-allocated, and have enough space to store
/// \c length elements. Returns \c YES on success.
- (BOOL)lt_scanCommaSeparatedFloats:(float *)values length:(size_t)length;

/// Scans \c length floating point elements and stores them into the given \c values, which
/// assumed to be pre-allocated and have enough space to hold \c length elements. Vector assumed
/// to be represented of this form \c {1, 2, 3}. Returns \c YES on success.
- (BOOL)lt_scanFloatVector:(float *)values length:(size_t)length;

/// Scans floating point elements matrix of size \c rows and \c cols and stores it into the given
/// \c values, which assumed to be pre-allocated and have enough space to hold it. Matrix assumed
/// to be of the following form \c {{1, 2}, {3, 4}} in row major order. Returns \c YES on success.
- (BOOL)lt_scanFloatMatrix:(float *)values rows:(size_t)rows cols:(size_t)cols;

@end

NS_ASSUME_NONNULL_END
