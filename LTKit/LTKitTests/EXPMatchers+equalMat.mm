// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+equalMat.h"

#import "LTTestUtils.h"
#import "NSValue+Expecta.h"
#import "NSValue+OpenCVExtensions.h"

EXPMatcherImplementationBegin(equalMat, (NSValue *expected)) {
  __block cv::Point firstMismatch;
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL{
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL{
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      return LTCompareMat([expected matValue], [actual matValue], &firstMismatch);
    }
  });

  failureMessageForTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected %@ at (%d, %d), got %@",
            LTMatValueAsString([expected matValue], firstMismatch),
            firstMismatch.x, firstMismatch.y,
            LTMatValueAsString([actual matValue], firstMismatch)];
  });

  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected not '%@' at (%d, %d), got '%@'",
            LTMatValueAsString([expected matValue], firstMismatch),
            firstMismatch.x, firstMismatch.y,
            LTMatValueAsString([actual matValue], firstMismatch)];
  });
}
EXPMatcherImplementationEnd
