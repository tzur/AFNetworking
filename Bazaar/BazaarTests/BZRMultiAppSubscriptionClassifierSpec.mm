// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRMultiAppSubscriptionClassifier.h"

SpecBegin(BZRMultiAppSubscriptionClassifier)

__block NSString *multiAppServiceLevelMarker;
__block BZRMultiAppSubscriptionClassifier *multiAppSubscriptionClassifier;

beforeEach(^{
  multiAppServiceLevelMarker = @"MultiApp";
  multiAppSubscriptionClassifier = [[BZRMultiAppSubscriptionClassifier alloc]
                                    initWithMultiAppServiceLevelMarker:multiAppServiceLevelMarker];
});

it(@"should return YES if the given product identifier contains the marker", ^{
  expect([multiAppSubscriptionClassifier
          isMultiAppSubscription:@"com.lt.foo_GroupName_A.MultiApp.B_Discount"]).to.beTruthy();
});

it(@"should return YES if the given product identifier contains the marker but no discount", ^{
  expect([multiAppSubscriptionClassifier
          isMultiAppSubscription:@"com.lt.foo_GroupName_A.MultiApp"]).to.beTruthy();
});

it(@"should return NO if the given product identifier does not contain the marker", ^{
  expect([multiAppSubscriptionClassifier
          isMultiAppSubscription:@"com.lt.foo_GroupName_SingleApp"]).to.beFalsy();
});

it(@"should return NO if the given product identifier is not in the expected format", ^{
  expect([multiAppSubscriptionClassifier isMultiAppSubscription:@"com.lt.foo_MultiApp"]).to
      .beFalsy();
});

it(@"should return NO if the given product identifier is an empty string", ^{
  expect([multiAppSubscriptionClassifier isMultiAppSubscription:@""]).to.beFalsy();
});

SpecEnd
