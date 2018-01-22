// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRMultiAppSubscriptionClassifier.h"

SpecBegin(BZRMultiAppSubscriptionClassifierSpec)

__block NSString *multiAppServiceLevelMarker;
__block BZRMultiAppSubscriptionClassifier *multiAppConfiguration;

beforeEach(^{
  multiAppServiceLevelMarker = @"MultiApp";
  multiAppConfiguration = [[BZRMultiAppSubscriptionClassifier alloc]
                           initWithMultiAppServiceLevelMarker:multiAppServiceLevelMarker];
});

it(@"should initialize with the given multi-app marker", ^{
  expect(multiAppConfiguration.multiAppServiceLevelMarker).to.equal(multiAppServiceLevelMarker);
});

it(@"should return YES if the given product identifier contains the marker", ^{
  expect([multiAppConfiguration
          isMultiAppSubscription:@"com.lt.foo_GroupName_A.MultiApp.B_Discount"]).to.beTruthy();
});

it(@"should return YES if the given product identifier contains the marker but no discount", ^{
  expect([multiAppConfiguration
          isMultiAppSubscription:@"com.lt.foo_GroupName_A.MultiApp"]).to.beTruthy();
});

it(@"should return NO if the given product identifier does not contain the marker", ^{
  expect([multiAppConfiguration
          isMultiAppSubscription:@"com.lt.foo_GroupName_SingleApp"]).to.beFalsy();
});

it(@"should return NO if the given product identifier is not in the expected format", ^{
  expect([multiAppConfiguration isMultiAppSubscription:@"com.lt.foo_MultiApp"]).to.beFalsy();
});

it(@"should return NO if the given product identifier is an empty string", ^{
  expect([multiAppConfiguration isMultiAppSubscription:@""]).to.beFalsy();
});

SpecEnd
