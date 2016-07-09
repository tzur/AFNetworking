// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTaskProgress.h"

#import "FBRHTTPResponse.h"

SpecBegin(FBRHTTPTaskProgress)

context(@"default initialization", ^{
  it(@"should initialize a task progress for a yet to be started task", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] init];

    expect(progress).toNot.beNil();
    expect(progress.progress).to.equal(0);
    expect(progress.hasStarted).to.beFalsy();
    expect(progress.hasCompleted).to.beFalsy();
    expect(progress.response).to.beNil();
  });
});

context(@"initialization with progress", ^{
  it(@"should initialize with the specified progress", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:0.5];
    expect(progress.progress).to.beCloseToWithin(0.5, DBL_EPSILON);
    expect(progress.response).to.beNil();
  });

  it(@"should indicate that the task has started if progress value is between 0 to 1", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:0.5];
    expect(progress.hasStarted).to.beTruthy();
  });

  it(@"should indicate that the task has not completed if progress value is between 0 to 1", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:0.5];
    expect(progress.hasCompleted).to.beFalsy();
  });

  it(@"should indicate that the task has not started if progress value is 0", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:0];
    expect(progress.hasStarted).to.beFalsy();
  });

  it(@"should indicate that the task has not completed if no resposne object is provided", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    expect(progress.hasCompleted).to.beFalsy();
  });

  it(@"should raise exception if progress is less than 0", ^{
    expect(^{
      FBRHTTPTaskProgress __unused *progress =
          [[FBRHTTPTaskProgress alloc] initWithProgress:-DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if progress is greater than 1", ^{
    expect(^{
      FBRHTTPTaskProgress __unused *progress =
          [[FBRHTTPTaskProgress alloc] initWithProgress:1 + DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"initialization with response", ^{
  __block FBRHTTPResponse *response;

  beforeEach(^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    NSHTTPURLResponse *responseMetadata =
        [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:nil headerFields:nil];
    NSData *responseContent = [@"Foo" dataUsingEncoding:NSUTF8StringEncoding];
    response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata content:responseContent];
  });

  it(@"should initialize with the given response", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithResponse:response];
    expect(progress.response).to.equal(response);
  });
  
  it(@"should indicate that the task has started and completed", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithResponse:response];
    expect(progress.progress).to.equal(1);
    expect(progress.hasStarted).to.beTruthy();
    expect(progress.hasCompleted).to.beTruthy();
  });
});

context(@"equality", ^{
  it(@"should indicate that two identical objects are equal", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    FBRHTTPTaskProgress *anotherProgress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];

    expect([progress isEqual:anotherProgress]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    FBRHTTPTaskProgress *anotherProgress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];

    expect(progress.hash).to.equal(anotherProgress.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    FBRHTTPTaskProgress *anotherProgress = [[FBRHTTPTaskProgress alloc] initWithProgress:0.5];

    expect([progress isEqual:anotherProgress]).to.beFalsy();
  });
});

context(@"copying", ^{
  it(@"should return a configuration identical to the copied configuration", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    FBRHTTPTaskProgress *anotherProgress = [progress copy];

    expect(progress).to.equal(anotherProgress);
  });
});

SpecEnd
