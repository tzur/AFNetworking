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

  expect(^{
    waitUntil(^(DoneCallback done) {
      [resourceRequest fbr_beginAccessingResourcesWithCompletionHandler:^(NSError *error) {
        errorBlockArgument = error;
        done();
      }];
    });
  }).toNot.raiseAny();
  expect(errorBlockArgument.code).to.equal(LTErrorCodeExceptionRaised);
});

it(@"should catch the raised exception and invoke the block with NO", ^{
  OCMStub([resourceRequest conditionallyBeginAccessingResourcesWithCompletionHandler:OCMOCK_ANY])
      .andThrow(exception);
  __block BOOL resourcesAvailableBlockArgument;

  expect(^{
    waitUntil(^(DoneCallback done) {
      [resourceRequest
       fbr_conditionallyBeginAccessingResourcesWithCompletionHandler:^(BOOL resourcesAvailable) {
         resourcesAvailableBlockArgument = resourcesAvailable;
         done();
       }];
    });
  }).toNot.raiseAny();
  expect(resourcesAvailableBlockArgument).to.beFalsy();
});

SpecEnd
