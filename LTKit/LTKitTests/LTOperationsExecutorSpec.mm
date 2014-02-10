// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOperationsExecutor.h"

#import "LTForegroundOperation.h"

SpecBegin(LTOperationsExecutor)

__block LTOperationsExecutor *executor;

beforeEach(^{
  executor = [[LTOperationsExecutor alloc] init];
});

context(@"execution", ^{
  __block NSMutableArray *values;
  __block LTForegroundOperation *operation;

  beforeEach(^{
    values = [NSMutableArray array];

    operation = [LTForegroundOperation blockOperationWithBlock:^{
      [values addObject:@1];
    }];
    [executor addOperation:operation];
  });

  context(@"execution allowed", ^{
    beforeEach(^{
      executor.executionAllowed = YES;
    });

    it(@"should execute single added foreground operation", ^{
      [executor executeAll];

      expect(values).to.equal(@[@1]);
    });

    it(@"should execute two added foreground operations in order", ^{
      LTForegroundOperation *anotherOperation = [LTForegroundOperation blockOperationWithBlock:^{
        [values addObject:@2];
      }];
      [executor addOperation:anotherOperation];
      [executor executeAll];

      expect(values).to.equal(@[@1, @2]);
    });

    it(@"should not execute added operation twice", ^{
      [executor executeAll];
      [executor executeAll];

      expect(values).to.equal(@[@1]);
    });
  });
  
  context(@"execution is not allowed", ^{
    it(@"should not execute added operations", ^{
      [executor executeAll];

      expect(values.count).to.equal(0);
    });
  });

  context(@"removal of operations", ^{
    it(@"should not execute removed operation", ^{
      executor.executionAllowed = YES;
      [executor removeOperation:operation];
      [executor executeAll];

      expect(values.count).to.equal(0);
    });
  });
});

SpecEnd
