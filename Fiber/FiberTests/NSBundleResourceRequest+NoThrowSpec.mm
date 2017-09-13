// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSBundleResourceRequest+NoThrow.h"

SpecBegin(NSBundleResourceRequest_NoThrow)

__block NSBundleResourceRequest *resourceRequest;
__block NSException *exception;

beforeEach(^{
  resourceRequest = OCMPartialMock([[NSBundleResourceRequest alloc]
                                    initWithTags:[NSSet setWithObject:@"foo"]]);
  exception = [[NSException alloc] initWithName:@"boo" reason:@"bar" userInfo:nil];
});

it(@"should catch the raised exception and invoke the block with an error", ^{
  OCMStub([resourceRequest beginAccessingResourcesWithCompletionHandler:OCMOCK_ANY])
      .andThrow(exception);
  __block NSError *errorBlockArgument;
  auto completionHandler = ^(NSError *error) {
    errorBlockArgument = error;
  };

  expect(^{
    [resourceRequest fbr_beginAccessingResourcesWithCompletionHandler:completionHandler];
  }).toNot.raiseAny();
  expect(errorBlockArgument.code).will.equal(LTErrorCodeExceptionRaised);
});

it(@"should catch the raised exception and invoke the block with NO", ^{
  OCMStub([resourceRequest conditionallyBeginAccessingResourcesWithCompletionHandler:OCMOCK_ANY])
      .andThrow(exception);
  __block BOOL blockInvoked;
  __block BOOL resourcesAvailableBlockArgument;
  auto completionHandler = ^(BOOL resourcesAvailable) {
    blockInvoked = YES;
    resourcesAvailableBlockArgument = resourcesAvailable;
  };

  expect(^{
    [resourceRequest
     fbr_conditionallyBeginAccessingResourcesWithCompletionHandler:completionHandler];
  }).toNot.raiseAny();
  expect(blockInvoked).will.beTruthy();
  expect(resourcesAvailableBlockArgument).will.beFalsy();
});

SpecEnd
