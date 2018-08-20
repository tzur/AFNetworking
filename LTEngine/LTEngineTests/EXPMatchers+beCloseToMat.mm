// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+beCloseToMat.h"

#import <Expecta/NSValue+Expecta.h>

#import "LTTestUtils+LTEngine.h"
#import "NSValue+OpenCVExtensions.h"

static double LTDefaultRangeForMatType(int type) {
  if (CV_MAT_DEPTH(type) == CV_32F || CV_MAT_DEPTH(type) == CV_16F) {
    return 1.0 / 255.0;
  } else {
    return 1.0;
  }
}

EXPMatcherImplementationBegin(_beCloseToMatWithin, (NSValue *expected, id within)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id actual) {
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    } else if (![within isKindOfClass:[NSNumber class]] && within != nil) {
      prerequisiteErrorMessage = @"Given range is not NSNumber or nil";
    } else if (![expected matValue].data) {
      prerequisiteErrorMessage = @"Expected mat data is null";
    } else if (![actual matValue].data) {
      prerequisiteErrorMessage = @"Actual mat data is null";
    }
    return !prerequisiteErrorMessage;
  });

  __block std::vector<int> firstMismatch([expected matValue].dims);

  match(^BOOL(id actual) {
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      const cv::Mat expectedMat([expected matValue]);
      const cv::Mat actualMat([actual matValue]);
      double range = within ? [within doubleValue] : LTDefaultRangeForMatType(expectedMat.type());
      return LTFuzzyCompareMat(expectedMat, actualMat, range, &firstMismatch);
    }
  });

  failureMessageForTo(^NSString *(id actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTWriteMatrices([expected matValue], [actual matValue]);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to be close to %@ "
              "within %@", LTMatValueAsString([expected matValue], firstMismatch),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch), within];
    } else {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@ to be close to %@",
              LTMatValueAsString([expected matValue], firstMismatch),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch)];
    }
  });

  failureMessageForNotTo(^NSString *(id actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTWriteMatrices([expected matValue], [actual matValue]);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@  to not be close "
              "to %@ within %@", LTMatValueAsString([expected matValue], firstMismatch),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch), within];
    } else {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@  to not be close "
              "to %@", LTMatValueAsString([expected matValue], firstMismatch),
              LTIndicesVectorAsString(firstMismatch),
              LTMatValueAsString([actual matValue], firstMismatch)];
    }
  });
}

EXPMatcherImplementationEnd
