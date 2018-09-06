// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+equalMat.h"

#import <Expecta/NSValue+Expecta.h>

#import "NSValue+OpenCVExtensions.h"

EXPMatcherImplementationBegin(equalMat, (NSValue *expected)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id) {
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    }
    return !prerequisiteErrorMessage;
  });

  __block std::vector<int> firstMismatch;

  match(^BOOL(id actual) {
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      return LTCompareMat([expected matValue], [actual matValue], &firstMismatch);
    }
  });

  failureMessageForTo(^NSString *(id actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTWriteMatrices([expected matValue], [actual matValue]);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    if (firstMismatch.empty()) {
      cv::Mat expectedMat = [expected matValue];
      cv::Mat actualMat = [actual matValue];
      return [NSString stringWithFormat:@"Metadata mismatch, expected: size (%d, %d), type %d, "
              "got: size (%d, %d), type %d", expectedMat.cols, expectedMat.rows, expectedMat.type(),
              actualMat.cols, actualMat.rows, actualMat.type()];
    } else {
      return [NSString stringWithFormat:@"First failure: expected %@ at %@, got %@",
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

    return @"Expected matrices not to be equal, got equal matrices";
  });
}

EXPMatcherImplementationEnd
