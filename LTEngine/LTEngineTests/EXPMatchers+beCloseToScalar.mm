// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+beCloseToScalar.h"

#import <Expecta/NSValue+Expecta.h>

#import "NSValue+OpenCVExtensions.h"

static double LTDefaultRangeForMatType(int type) {
  if (CV_MAT_DEPTH(type) == CV_32F || CV_MAT_DEPTH(type) == CV_16F) {
    return 1.0 / 255.0;
  } else {
    return 1.0;
  }
}

EXPMatcherImplementationBegin(_beCloseToScalarWithin, (NSValue *expected, id within)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id actual) {
    if (strcmp([expected _EXP_objCType], @encode(cv::Scalar))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Scalar";
    } else if (![within isKindOfClass:[NSNumber class]] && within != nil) {
      prerequisiteErrorMessage = @"Given range is not NSNumber or nil";
    } else if (![actual matValue].data) {
      prerequisiteErrorMessage = @"Actual mat data is null";
    }
    return !prerequisiteErrorMessage;
  });

  __block std::vector<int> firstMismatch;

  match(^BOOL(id actual) {
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      const cv::Scalar expectedScalar([expected scalarValue]);
      const cv::Mat actualMat([actual matValue]);
      double range = within ? [within doubleValue] : LTDefaultRangeForMatType(actualMat.type());
      return LTFuzzyCompareMatWithValue(expectedScalar, actualMat, range, &firstMismatch);
    }
  });

  failureMessageForTo(^NSString *(id actual) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to be close to %@ "
              "within %@", LTScalarAsString([expected scalarValue]),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch), within];
    } else {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to be close to %@",
              LTScalarAsString([expected scalarValue]),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch)];
    }
  });

  failureMessageForNotTo(^NSString *(id actual) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to not be close "
              "to %@ within %@", LTScalarAsString([expected scalarValue]),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch), within];
    } else {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to not be close "
              "to %@", LTScalarAsString([expected scalarValue]),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch)];
    }
  });
}
EXPMatcherImplementationEnd
