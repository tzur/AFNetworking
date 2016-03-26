// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "EXPMatchers+equalMat.h"

#import <Expecta/NSValue+Expecta.h>

#import "NSValue+OpenCVExtensions.h"

EXPMatcherImplementationBegin(equalMat, (NSValue *expected)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL{
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    }
    return !prerequisiteErrorMessage;
  });

  __block std::vector<int> firstMismatch([expected matValue].dims);

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
    return [NSString stringWithFormat:@"First failure: expected %@ at %@, got %@",
            LTMatValueAsString([expected matValue], firstMismatch),
            LTIndicesVectorAsString(firstMismatch),
            LTMatValueAsString([actual matValue], firstMismatch)];
  });

  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    return [NSString stringWithFormat:@"First failure: expected not '%@' at %@, got '%@'",
            LTMatValueAsString([expected matValue], firstMismatch),
            LTIndicesVectorAsString(firstMismatch),
            LTMatValueAsString([actual matValue], firstMismatch)];
  });
}

EXPMatcherImplementationEnd
