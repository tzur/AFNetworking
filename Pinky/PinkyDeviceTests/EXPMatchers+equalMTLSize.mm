// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "EXPMatchers+equalMTLSize.h"

#import <Expecta/NSValue+Expecta.h>

#import "LTEasyBoxing+Pinky.h"

EXPMatcherImplementationBegin(equalMTLSize, (NSValue *expectedValue)) {
  __block NSString *prerequisiteErrorMessage;

  prerequisite(^BOOL(id) {
    if (strcmp([expectedValue _EXP_objCType], @encode(MTLSize))) {
      prerequisiteErrorMessage = @"Size value is not MTLSize";
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL(id actual) {
    MTLSize expected = [expectedValue MTLSizeValue];
    MTLSize result = [actual MTLSizeValue];
    return expected.width == result.width && expected.height == result.height &&
        expected.depth == result.depth;
  });

  failureMessageForTo(^NSString *(id actual) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    MTLSize expected = [expectedValue MTLSizeValue];
    MTLSize result = [actual MTLSizeValue];
    return [NSString stringWithFormat:@"expected (%lu, %lu, %lu), got (%lu, %lu, %lu)",
            expected.width, expected.height, expected.depth, result.width, result.height,
            result.depth];
  });

  failureMessageForNotTo(^NSString *(id) {
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    MTLSize expected = [expectedValue MTLSizeValue];
    return [NSString stringWithFormat:@"got unwanted expected value (%lu, %lu, %lu)",
            expected.width, expected.height, expected.depth];
  });
}

EXPMatcherImplementationEnd
