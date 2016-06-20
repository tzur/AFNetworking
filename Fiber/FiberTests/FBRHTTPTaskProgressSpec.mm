// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTaskProgress.h"

SpecBegin(FBRHTTPTaskProgress)

context(@"default initialization", ^{
  it(@"should initialize a task progress for a yet to be started task", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] init];

    expect(progress).toNot.beNil();
    expect(progress.progress).to.equal(0);
    expect(progress.hasStarted).to.beFalsy();
    expect(progress.hasCompleted).to.beFalsy();
    expect(progress.responseData).to.beNil();
  });
});

context(@"initialization with progress", ^{
  it(@"should initialize with the specified progress", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:0.5];
    expect(progress.progress).to.beCloseToWithin(0.5, DBL_EPSILON);
    expect(progress.responseData).to.beNil();
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

  it(@"should indicate that the task has completed if progress value is 1", ^{
    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithProgress:1];
    expect(progress.hasCompleted).to.beTruthy();
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

context(@"initialization with response data", ^{
  context(@"non null response data", ^{
    __block NSData *responseData;

    beforeEach(^{
      responseData = [@"Foo" dataUsingEncoding:NSUTF8StringEncoding];
    });

    it(@"should initialize with the given response data", ^{
      FBRHTTPTaskProgress *progress =
          [[FBRHTTPTaskProgress alloc] initWithResponseData:responseData];
      expect(progress.responseData).to.equal(responseData);
    });

    it(@"should indicate that the task has started and completed", ^{
      FBRHTTPTaskProgress *progress =
          [[FBRHTTPTaskProgress alloc] initWithResponseData:responseData];
      expect(progress.hasStarted).to.beTruthy();
      expect(progress.hasCompleted).to.beTruthy();
    });
  });


  context(@"nil response data", ^{
    it(@"should initialize with nil response data", ^{
      FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithResponseData:nil];
      expect(progress).toNot.beNil();
      expect(progress.responseData).to.beNil();
      expect(progress.progress).to.equal(1);
    });

    it(@"should indicate that the task has started and completed", ^{
      FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithResponseData:nil];
      expect(progress.hasStarted).to.beTruthy();
      expect(progress.hasCompleted).to.beTruthy();
    });
  });
});

SpecEnd
