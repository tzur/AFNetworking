// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "EXPMatchers+beCloseToCATransform3D.h"

#import <cmath>

static NS_RETURNS_RETAINED NSString *descriptionOf(const CATransform3D transform) {
  NSMutableArray *entries = [NSMutableArray array];
  const CGFloat *entry = (CGFloat *)(&transform);
  for (NSUInteger i = 0; i < sizeof(CATransform3D) / sizeof(CGFloat); ++i) {
    [entries addObject:@(entry[i])];
  }
  return [entries componentsJoinedByString:@","];
}

EXPMatcherImplementationBegin(_beCloseToCATransform3DWithin, (id expected, id within)) {
  __block NSString *prerequisiteErrorMessage;
  __block CATransform3D expectedTransform, actualTransform;

  prerequisite(^BOOL{
    if (!([expected isKindOfClass:[NSValue class]] && [actual isKindOfClass:[NSValue class]])) {
      prerequisiteErrorMessage = @"Expected value must be CATransform3D.";
    } else if (within && ![within isKindOfClass:[NSNumber class]]) {
      prerequisiteErrorMessage = @"Given range must be NSNumber or nil.";
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL{
    [((NSValue *)expected) getValue:&expectedTransform];
    [((NSValue *)actual) getValue:&actualTransform];
    double range = within ? [within doubleValue] : FLT_MIN;
    const CGFloat *expectedEntry = (CGFloat *)(&expectedTransform);
    const CGFloat *actualEntry = (CGFloat *)(&actualTransform);
    for (NSUInteger i = 0; i < sizeof(CATransform3D) / sizeof(CGFloat); ++i) {
      if (std::abs(expectedEntry[i] - actualEntry[i]) > range) {
        return NO;
      }
    }
    return YES;
  });

  failureMessageForTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    if (within) {
      return [NSString stringWithFormat:@"Expected (%@) to be close to (%@) within %@.",
              descriptionOf(actualTransform), descriptionOf(expectedTransform), within];
    } else {
      return [NSString stringWithFormat:@"Expected (%@) to be close to (%@).",
              descriptionOf(actualTransform), descriptionOf(expectedTransform)];
    }
  });

  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    if (within) {
      return [NSString stringWithFormat:@"Expected (%@) not to be close to (%@) within %@.",
              descriptionOf(actualTransform), descriptionOf(expectedTransform), within];
    } else {
      return [NSString stringWithFormat:@"Expected (%@) not to be close to (%@).",
              descriptionOf(actualTransform), descriptionOf(expectedTransform)];
    }
  });
}

EXPMatcherImplementationEnd
