// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "EXPMatchers+beCloseToPoint.h"

#import <EXPFloatTuple.h>
#import <EXPDoubleTuple.h>

#import "LTCGExtensions.h"
#import "NSValue+Expecta.h"

EXPMatcherImplementationBegin(_beCloseToPointWithin, (id expected, id within)) {
  __block CGFloat distance;
  __block NSString *prerequisiteErrorMessage;
  __block CGPoint expectedPoint;
  __block CGPoint actualPoint;
  
  prerequisite(^BOOL{
    if (!(([expected isKindOfClass:[EXPFloatTuple class]] &&
          [actual isKindOfClass:[EXPFloatTuple class]]) ||
         ([expected isKindOfClass:[EXPDoubleTuple class]] &&
         [actual isKindOfClass:[EXPDoubleTuple class]]))) {
      prerequisiteErrorMessage = @"Expected value is not CGPoint";
    } else if (![within isKindOfClass:[NSNumber class]] && within != nil) {
      prerequisiteErrorMessage = @"Given range is not NSNumber or nil";
    }
    return !prerequisiteErrorMessage;
  });
  
  match(^BOOL{
    if ([expected isKindOfClass:[EXPFloatTuple class]]) {
      expectedPoint = CGPointMake([(EXPFloatTuple *)expected values][0],
                                  [(EXPFloatTuple *)expected values][1]);
      actualPoint = CGPointMake([(EXPFloatTuple *)actual values][0],
                                [(EXPFloatTuple *)actual values][1]);
    } else {
      expectedPoint = CGPointMake([(EXPDoubleTuple *)expected values][0],
                                  [(EXPDoubleTuple *)expected values][1]);
      actualPoint = CGPointMake([(EXPDoubleTuple *)actual values][0],
                                [(EXPDoubleTuple *)actual values][1]);
    }
    double range = [within doubleValue];
    distance = CGPointDistance(expectedPoint, actualPoint);
    return distance <= range;
  });
  
  failureMessageForTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"Expected (%g,%g) to be close to (%g,%g) within %@. "
              "Distance is %g instead.", actualPoint.x, actualPoint.y, expectedPoint.x,
              expectedPoint.y, within, distance];
    } else {
      return [NSString stringWithFormat:@"Expected (%g,%g) to be close to (%g,%g). Distance is %g.",
              actualPoint.x, actualPoint.y, expectedPoint.x, expectedPoint.y, distance];
    }
  });
  
  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }
    if (within) {
      return [NSString stringWithFormat:@"Expected (%g,%g) not to be close to (%g,%g) within %@. "
              "Distance is %g instead.", actualPoint.x, actualPoint.y, expectedPoint.x,
              expectedPoint.y, within, distance];
    } else {
      return [NSString stringWithFormat:@"Expected (%g,%g) not to be close to (%g,%g). Distance is "
              "%g.", actualPoint.x, actualPoint.y, expectedPoint.x, expectedPoint.y, distance];
    }
  });
}

EXPMatcherImplementationEnd
