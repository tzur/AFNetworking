// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTProgress.h"

/// Dummy object used as \c ResultType in \c LTProgress tests.
@interface LTDummyResult : NSObject

/// Value of the result.
@property (readonly, nonatomic) NSString *value;

@end

@implementation LTDummyResult

- (instancetype)initWithValue:(NSString *)value {
  if (self = [super init]) {
    _value = value;
  }
  return self;
}

- (BOOL)isEqual:(LTDummyResult *)object {
  if (object == self) {
    return YES;
  }

  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [object.value isEqual:self.value];
}

@end

SpecBegin(LTProgress)

context(@"default initialization", ^{
  it(@"should initialize a task progress for a yet to be started task", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] init];

    expect(progress).toNot.beNil();
    expect(progress.progress).to.equal(0);
    expect(progress.result).to.beNil();
  });
});

context(@"initialization with progress", ^{
  it(@"should initialize with the specified progress", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithProgress:0.5];
    expect(progress.progress).to.beCloseToWithin(0.5, DBL_EPSILON);
    expect(progress.result).to.beNil();
  });

  it(@"should raise exception if progress is less than 0", ^{
    expect(^{
      LTProgress __unused *progress = [[LTProgress alloc] initWithProgress:-DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if progress is greater than 1", ^{
    expect(^{
      LTProgress __unused *progress = [[LTProgress alloc] initWithProgress:1 + DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"initialization with result", ^{
  it(@"should initialize with the given result", ^{
    LTDummyResult *result = [[LTDummyResult alloc] initWithValue:@"foo"];
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithResult:result];
    expect(progress.result).to.equal(result);
  });
});

context(@"map", ^{
  it(@"should return object with the same progress value if result is nil", ^{
    LTProgress<NSString *> *progress = [LTProgress progressWithProgress:0.5];
    LTProgress *mappedProgress = [progress map:^NSNumber *(NSString * __unused object) {
      return @5;
    }];

    expect(mappedProgress.progress).to.equal(0.5);
    expect(mappedProgress.result).to.beNil();
  });

  it(@"should return object with result of block if result is not nil", ^{
    LTProgress<NSString *> *progress = [LTProgress progressWithResult:@"A"];
    LTProgress *mappedProgress = [progress map:^NSString *(NSString *string) {
      return [string stringByAppendingString:@"B"];
    }];

    expect(mappedProgress.progress).to.equal(1);
    expect(mappedProgress.result).to.equal(@"AB");
  });
});

context(@"equality", ^{
  __block LTDummyResult *result;

  beforeEach(^{
    result = [[LTDummyResult alloc] initWithValue:@"foo"];
  });

  it(@"should indicate that two objects with same progress value and no result are equal", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithProgress:1];
    LTProgress<LTDummyResult *> *anotherProgress = [[LTProgress alloc] initWithProgress:1];

    expect([progress isEqual:anotherProgress]).to.beTruthy();
  });

    it(@"should indicate that two objects with same progress value and result are equal", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithResult:result];
    LTProgress<LTDummyResult *> *anotherProgress = [[LTProgress alloc] initWithResult:result];

    expect([progress isEqual:anotherProgress]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithProgress:1];
    LTProgress<LTDummyResult *> *anotherProgress = [[LTProgress alloc] initWithProgress:1];

    expect(progress.hash).to.equal(anotherProgress.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithProgress:1];
    LTProgress<LTDummyResult *> *anotherProgress = [[LTProgress alloc] initWithProgress:0.5];

    expect([progress isEqual:anotherProgress]).to.beFalsy();
  });
});

context(@"copying", ^{
  it(@"should return a progress identical to the copied progress", ^{
    LTProgress<LTDummyResult *> *progress = [[LTProgress alloc] initWithProgress:1];
    LTProgress<LTDummyResult *> *anotherProgress = [progress copy];

    expect(progress).to.equal(anotherProgress);
  });
});

SpecEnd
