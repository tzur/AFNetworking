// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ophir Abitbol.

#import "EXPMatchers+beCloseToGLKMatrix.h"

/// Holds the name and value of a GLKMatrix. First value holds the name of the specific GLKMatrix
/// (e.g. "GLKMatrix2"), second value contains the actual matrix data.
typedef std::pair<NSString *, std::vector<float>> LTMatrixNameAndValue;

/// Returns the name of the provided matrix. Currently supports \c GLKMatrix2, \c GLKMatrix3
/// and \c GLKMatrix4.
static NSString *LTMatrixNameFromValue(NSValue *matrix) {
  if (strcmp(matrix.objCType, @encode(GLKMatrix2)) == 0) {
    return @"GLKMatrix2";
  } else if (strcmp(matrix.objCType, @encode(GLKMatrix3)) == 0) {
    return @"GLKMatrix3";
  } else if (strcmp(matrix.objCType, @encode(GLKMatrix4)) == 0) {
    return @"GLKMatrix4";
  }
  return @"Unknown";
}

/// Returns the value of the provided matrix.
static std::vector<float> LTMatrixValueFromValue(NSValue *matrix) {
  NSUInteger length;
  NSGetSizeAndAlignment(matrix.objCType, &length, NULL);
  std::vector<float> value(length / sizeof(float));
  [matrix getValue:value.data()];
  return value;
}

/// Creates an \c LTMatrixNameAndValue from the provided \c matrix and sets it in \c glkmatrix.
/// Currently supports \c GLKMatrix2, \c GLKMatrix3 and \c GLKMatrix4. Returns \c NO if the given
/// \c nameToValue pair is unsupported.
static BOOL LTGLKMatrixFromValue(NSValue *matrix, LTMatrixNameAndValue *glkmatrix) {
  *glkmatrix = {LTMatrixNameFromValue(matrix), LTMatrixValueFromValue(matrix)};
  if ([glkmatrix->first isEqualToString:@"Unknown"]) {
    return false;
  }
  return true;
}

/// Calculates a comparison range for the given floats. Since you can't simply compare floats,
/// \c FLT_EPSILON is usually used as a range to determine how close they are to one another.
/// However, depending on the magnitude of the floats compared, \c FLT_EPSILON might be too large.
/// Hence, this method returns a comparison range which is \b relative to the given floats.
///
/// @see https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
static float LTRangeForComparingFloats(float a, float b) {
  return std::max(std::abs(a), std::abs(b)) * FLT_EPSILON;
}

/// Compares the provided matrices. Returns \c NO If matrices don't match and sets \c firstMismatch
/// to the index of the first mismatch. If provided, uses \c range to compare the values, o.w.
/// uses \c LTRangeForComparingFloats to create a relative range for every pair of compared floats.
static BOOL LTCompareGLKMatrixWithin(LTMatrixNameAndValue const &expected,
                                     LTMatrixNameAndValue const &actual,
                                     NSNumber *range,
                                     NSUInteger *firstMismatch) {
  NSUInteger length = expected.second.size();
  for (NSUInteger i = 0; i < length; ++i) {
    double currentRange = range ? range.doubleValue :
        LTRangeForComparingFloats(expected.second[i], actual.second[i]);
    if (std::abs(expected.second[i] - actual.second[i]) > currentRange) {
      if (firstMismatch) {
        *firstMismatch = i;
      }
      return NO;
    }
  }
  return YES;
}

EXPMatcherImplementationBegin(_beCloseToGLKMatrixWithin, (NSValue *expected, id range)) {
  __block NSUInteger firstMismatch;
  __block LTMatrixNameAndValue expectedMat;
  __block LTMatrixNameAndValue actualMat;
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id actual) {
    if (![expected isKindOfClass:NSValue.class]) {
      prerequisiteErrorMessage = @"Expected type is not NSValue";
    }
    bool isValidExpected = LTGLKMatrixFromValue(expected, &expectedMat);
    if (!isValidExpected) {
      prerequisiteErrorMessage = @"Expected value is not a GLKMatrix";
      return false;
    }
    if (![actual isKindOfClass:NSValue.class]) {
      prerequisiteErrorMessage = @"Actual type is not NSValue";
      return false;
    }
    bool isValidActual = LTGLKMatrixFromValue(actual, &actualMat);
    if (!isValidActual) {
      prerequisiteErrorMessage = @"Expected value is not a GLKMatrix";
      return false;
    }
    if (![actualMat.first isEqualToString:expectedMat.first]) {
      prerequisiteErrorMessage = [NSString stringWithFormat:
                                  @"Size mismatch: expected is of type %@, actual is of type %@",
                                  expectedMat.first, actualMat.first];
      return false;
    }
    return true;
  });

  match(^BOOL(id actual) {
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      return LTCompareGLKMatrixWithin(expectedMat, actualMat, range, &firstMismatch);
    }
  });

  failureMessageForTo(^NSString *(id) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    double currentRange = range ? [range doubleValue] :
        LTRangeForComparingFloats(expectedMat.second[firstMismatch],
                                  actualMat.second[firstMismatch]);
    return [NSString stringWithFormat:@"Expected %f +/- %f at index %lu, got %f",
            expectedMat.second[firstMismatch], currentRange, (unsigned long)firstMismatch,
            actualMat.second[firstMismatch]];
  });

  failureMessageForNotTo(^NSString *(id) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"Matrices match when expected not to"];
  });
}

EXPMatcherImplementationEnd
