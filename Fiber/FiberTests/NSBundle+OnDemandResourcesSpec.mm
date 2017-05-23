// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSBundle+OnDemandResources.h"

#import <LTKit/LTProgress.h>

#import "NSErrorCodes+Fiber.h"

/// Category for testing, exposes the method that creates the inner resource request.
@interface NSBundle (OnDemandResourcesTests)

- (NSBundleResourceRequest *)fbr_bundleResourceRequestWithTags:(NSSet<NSString *> *)tags;

@end

SpecBegin(NSBundle_OnDemandResources)

__block NSBundle *bundle;
__block NSBundleResourceRequest *resourceRequest;

beforeEach(^{
  bundle = OCMPartialMock([[NSBundle alloc] init]);
  resourceRequest = OCMClassMock([NSBundleResourceRequest class]);
  OCMStub([bundle fbr_bundleResourceRequestWithTags:OCMOCK_ANY]).andReturn(resourceRequest);
});

context(@"begin accessing resources", ^{
  __block NSProgress *progress;

  beforeEach(^{
    progress = [NSProgress progressWithTotalUnitCount:100];
    OCMStub([resourceRequest progress]).andReturn(progress);
  });

  it(@"should err when the inner resource request errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([resourceRequest beginAccessingResourcesWithCompletionHandler:
             ([OCMArg invokeBlockWithArgs:error,nil])]);

    LLSignalTestRecorder *recorder =
        [[bundle fbr_beginAccessToResourcesWithTags:[NSSet set]] testRecorder];

    expect(recorder).will.sendError(
      [NSError lt_errorWithCode:FBRErrorCodeOnDemandResourcesRequestFailed underlyingError:error]
    );
  });

  it(@"should return the progress with the inner progress value of the request", ^{
    LLSignalTestRecorder *recorder =
        [[bundle fbr_beginAccessToResourcesWithTags:[NSSet set]] testRecorder];

    progress.completedUnitCount = 10;
    progress.completedUnitCount = 50;
    progress.completedUnitCount = 100;

    expect(recorder).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.0],
      [[LTProgress alloc] initWithProgress:0.1],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1.0]
    ]);
    expect(recorder).toNot.complete();
  });

  it(@"should return progress with the resource as the result when the resource is available", ^{
    OCMStub([resourceRequest beginAccessingResourcesWithCompletionHandler:
             ([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);

    LLSignalTestRecorder *recorder =
        [[bundle fbr_beginAccessToResourcesWithTags:[NSSet set]] testRecorder];

    expect(recorder).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0],
      [[LTProgress alloc] initWithResult:resourceRequest]
    ]);
    expect(recorder).to.complete();
  });
});

context(@"conditionally begin accessing resources", ^{
  it(@"should return the resource if the resource is available on the device", ^{
    OCMStub([resourceRequest conditionallyBeginAccessingResourcesWithCompletionHandler:
             ([OCMArg invokeBlockWithArgs:@(YES), nil])]);

    LLSignalTestRecorder *recorder =
        [[bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet set]] testRecorder];

    expect(recorder).will.sendValues(@[resourceRequest]);
    expect(recorder).to.complete();
  });

  it(@"should return return nil if the resource is unavailable", ^{
    OCMStub([resourceRequest conditionallyBeginAccessingResourcesWithCompletionHandler:
             ([OCMArg invokeBlockWithArgs:@(NO), nil])]);

    LLSignalTestRecorder *recorder =
        [[bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet set]] testRecorder];

    expect(recorder).will.sendValues(@[[NSNull null]]);
    expect(recorder).to.complete();
  });
});

SpecEnd
