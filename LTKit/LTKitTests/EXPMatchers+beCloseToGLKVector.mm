// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "EXPMatchers+beCloseToGLKVector.h"

#import <Expecta/EXPDoubleTuple.h>
#import <Expecta/EXPFloatTuple.h>
#import <Expecta/NSValue+Expecta.h>

#import "LTGLKitExtensions.h"

static const double kDefaultWithinValue = 1e-6;

static NS_RETURNS_RETAINED NSString *descriptionOf(const std::vector<double> &vector) {
  NSMutableArray *array = [NSMutableArray array];
  for (const double &value : vector) {
    [array addObject:@(value)];
  }
  return [array componentsJoinedByString:@","];
}

EXPMatcherImplementationBegin(_beCloseToGLKVectorWithin, (id expected, id length, id within)) {
  __block NSString *prerequisiteErrorMessage;
  __block std::vector<double> expectedVector;
  __block std::vector<double> actualVector;
  
  prerequisite(^BOOL{
    if (!(([expected isKindOfClass:[EXPFloatTuple class]] &&
           [actual isKindOfClass:[EXPFloatTuple class]]) ||
          ([expected isKindOfClass:[EXPDoubleTuple class]] &&
           [actual isKindOfClass:[EXPDoubleTuple class]]))) {
            prerequisiteErrorMessage = @"Expected value is not GLKVector";
          } else if (![within isKindOfClass:[NSNumber class]] && within != nil) {
            prerequisiteErrorMessage = @"Given range is not NSNumber or nil";
          }
    return !prerequisiteErrorMessage;
  });
  
  match(^BOOL{
    double range = within ? [within doubleValue] : kDefaultWithinValue;
    if ([expected isKindOfClass:[EXPFloatTuple class]]) {
      for (NSUInteger i = 0; i < [length unsignedIntegerValue]; ++i) {
        expectedVector.push_back([(EXPFloatTuple *)expected values][i]);
        actualVector.push_back([(EXPFloatTuple *)actual values][i]);
      }
    } else {
      for (NSUInteger i = 0; i < [length unsignedIntegerValue]; ++i) {
        expectedVector.push_back([(EXPDoubleTuple *)expected values][i]);
        actualVector.push_back([(EXPDoubleTuple *)actual values][i]);
      }
    }
    
    for (auto eIter = expectedVector.cbegin(), aIter = actualVector.cbegin();
         eIter != expectedVector.cend() && aIter != actualVector.cend(); ++eIter, ++aIter) {
      if (isnan(*eIter) != isnan(*aIter)) {
        return NO;
      }
      if (ABS(*eIter - *aIter) > range) {
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
              descriptionOf(actualVector), descriptionOf(expectedVector), within];
    } else {
      return [NSString stringWithFormat:@"Expected (%@) to be close to (%@).",
              descriptionOf(actualVector), descriptionOf(expectedVector)];
    }
  });
  
  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    
    NSMutableArray *expectedArray = [NSMutableArray array];
    NSMutableArray *actualArray = [NSMutableArray array];
    for (double &value : expectedVector) {
      [expectedArray addObject:@(value)];
    }
    for (double &value : actualVector) {
      [actualArray addObject:@(value)];
    }
    
    if (within) {
      return [NSString stringWithFormat:@"Expected (%@) not to be close to (%@) within %@.",
              descriptionOf(actualVector), descriptionOf(expectedVector), within];
    } else {
      return [NSString stringWithFormat:@"Expected (%@) not to be close to (%@).",
              descriptionOf(actualVector), descriptionOf(expectedVector)];
    }
  });
}

EXPMatcherImplementationEnd
