// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "XCUIElement+ElementState.h"

NS_ASSUME_NONNULL_BEGIN

@implementation XCUIElement (ElementState)

- (BOOL)lt_waitForHittabilityWithTimeout:(NSTimeInterval)timeout {
  auto hittablePredicate = [NSPredicate predicateWithFormat:@"hittable == true"];
  auto hittableExpectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:hittablePredicate
                                                                           object:self];
  auto hittableExpectationResult = [XCTWaiter waitForExpectations:@[hittableExpectation]
                                                          timeout:timeout];
  return hittableExpectationResult == XCTWaiterResultCompleted;
}

@end

NS_ASSUME_NONNULL_END
