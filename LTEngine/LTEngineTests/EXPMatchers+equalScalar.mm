// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+equalScalar.h"

#import <Expecta/NSValue+Expecta.h>

#import "NSValue+OpenCVExtensions.h"

EXPMatcherImplementationBegin(equalScalar, (NSValue *scalar)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id actual) {
    if (strcmp([scalar _EXP_objCType], @encode(cv::Scalar))) {
      prerequisiteErrorMessage = @"Scalar value is not cv::Scalar";
    } else if (![actual matValue].data) {
      prerequisiteErrorMessage = @"Actual mat data is null";
    }
    return !prerequisiteErrorMessage;
  });

  __block std::vector<int> firstMismatch;

  match(^BOOL(id actual) {
    return LTCompareMatWithValue([scalar scalarValue], [actual matValue], &firstMismatch);
  });

  failureMessageForTo(^NSString *(id actual) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected %@ at %@, got %@",
            LTScalarAsString([scalar scalarValue]),
            LTIndicesVectorAsString(firstMismatch),
            LTMatValueAsString([actual matValue], firstMismatch)];
  });

  failureMessageForNotTo(^NSString *(id actual) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected not '%@' at %@, got '%@'",
            LTScalarAsString([scalar scalarValue]),
            LTIndicesVectorAsString(firstMismatch),
            LTMatValueAsString([actual matValue], firstMismatch)];
  });
}

EXPMatcherImplementationEnd
