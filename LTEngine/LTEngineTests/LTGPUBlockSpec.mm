// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUBlock.h"

#import "LTForegroundOperation.h"
#import "LTOperationsExecutor.h"

@interface LTOperationsExecutor ()

@property (strong, nonatomic) NSMutableArray *operations;

@end

@interface LTOperationsExecutor (ForTesting)

- (void)reset;

@end

@implementation LTOperationsExecutor (ForTesting)

- (void)reset {
  self.executionAllowed = NO;
  self.operations = [NSMutableArray array];
}

@end

SpecBegin(LTGPUBlock)

beforeEach(^{
  [[LTForegroundOperation executor] reset];
});

context(@"LTGPUBlock", ^{
  it(@"should not execute block when execution is disallowed", ^{
    __block BOOL didExecute = NO;

    LTGPUBlock(^{
      didExecute = YES;
    });

    expect(didExecute).to.beFalsy();
  });

  it(@"should execute block immediately when execution is allowed", ^{
    [LTForegroundOperation executor].executionAllowed = YES;

    __block BOOL didExecute = NO;

    LTGPUBlock(^{
      didExecute = YES;
    });
    
    expect(didExecute).to.beTruthy();
  });

  it(@"should execute block in delay after execution is allowed", ^{
    __block BOOL didExecute = NO;

    LTGPUBlock(^{
      didExecute = YES;
    });

    [LTForegroundOperation executor].executionAllowed = YES;
    [[LTForegroundOperation executor] executeAll];

    expect(didExecute).to.beTruthy();
  });
});

context(@"LTGPUCompletion", ^{
  it(@"should not execute block when execution is disallowed", ^{
    __block BOOL didExecute = NO;

    LTGPUCompletion(^{
      didExecute = YES;
    })();

    expect(didExecute).to.beFalsy();
  });

  it(@"should execute block immediately when execution is allowed", ^{
    [LTForegroundOperation executor].executionAllowed = YES;

    __block BOOL didExecute = NO;

    LTGPUCompletion(^{
      didExecute = YES;
    })();

    expect(didExecute).to.beTruthy();
  });

  it(@"should execute block in delay after execution is allowed", ^{
    __block BOOL didExecute = NO;

    LTGPUCompletion(^{
      didExecute = YES;
    })();

    [LTForegroundOperation executor].executionAllowed = YES;
    [[LTForegroundOperation executor] executeAll];

    expect(didExecute).to.beTruthy();
  });
});

SpecEnd
