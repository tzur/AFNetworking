// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+equalScalar.h"

#import <Expecta/NSValue+Expecta.h>

#import "LTTestUtils.h"
#import "NSValue+OpenCVExtensions.h"

EXPMatcherImplementationBegin(equalScalar, (NSValue *scalar)) {
  __block cv::Point firstMismatch;
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL{
    if (strcmp([scalar _EXP_objCType], @encode(cv::Scalar))) {
      prerequisiteErrorMessage = @"Scalar value is not cv::Scalar";
    } else if (![actual matValue].data) {
      prerequisiteErrorMessage = @"Actual mat data is null";
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL{
    return LTCompareMatWithValue([scalar scalarValue], [actual matValue], &firstMismatch);
  });

  failureMessageForTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected %@ at (%d, %d), got %@",
            LTScalarAsString([scalar scalarValue]), firstMismatch.x, firstMismatch.y,
            LTMatValueAsString([actual matValue], firstMismatch)];
  });

  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected not '%@' at (%d, %d), got '%@'",
            LTScalarAsString([scalar scalarValue]), firstMismatch.x, firstMismatch.y,
            LTMatValueAsString([actual matValue], firstMismatch)];
  });
}
EXPMatcherImplementationEnd
