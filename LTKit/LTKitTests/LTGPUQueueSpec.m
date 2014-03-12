// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUQueue.h"

#import "LTGLException.h"

SpecBegin(LTGPUQueue)

__block LTGPUQueue *queue;
__block dispatch_time_t semaphoreWaitTime;

beforeEach(^{
  queue = [[LTGPUQueue alloc] init];
  semaphoreWaitTime = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
});

context(@"async blocks", ^{
  __block dispatch_semaphore_t semaphore;

  beforeEach(^{
    queue.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    queue.failureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    semaphore = dispatch_semaphore_create(0);
  });

  it(@"should execute block", ^{
    __block BOOL ranBlock = NO;

    [queue runAsync:^{
      ranBlock = YES;
      dispatch_semaphore_signal(semaphore);
    } completion:nil];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(ranBlock).to.beTruthy();
  });

  it(@"should call completion block", ^{
    __block BOOL calledCompletion = NO;
    __block BOOL causedError = NO;

    [queue runAsync:^{
    } completion:^{
      calledCompletion = YES;
      dispatch_semaphore_signal(semaphore);
    } failure:^BOOL(NSError __unused *error) {
      causedError = YES;
      dispatch_semaphore_signal(semaphore);
      return YES;
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(calledCompletion).to.beTruthy();
    expect(causedError).to.beFalsy();
  });

  it(@"should call error block on exception", ^{
    __block BOOL calledCompletion = NO;
    __block BOOL causedError = NO;

    [queue runAsync:^{
      [LTGLException raise:@"MyError" format:@"description"];
    } completion:^{
      calledCompletion = YES;
      dispatch_semaphore_signal(semaphore);
    } failure:^BOOL(NSError __unused *error) {
      causedError = YES;
      dispatch_semaphore_signal(semaphore);
      return YES;
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(calledCompletion).to.beFalsy();
    expect(causedError).to.beTruthy();
  });

  it(@"should execute recursive blocks", ^{
    __block BOOL ranBlock = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue runAsync:^{
      [queue runAsync:^{
        ranBlock = YES;
        dispatch_semaphore_signal(semaphore);
      } completion:nil];
    } completion:nil];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(ranBlock).to.beTruthy();
  });
});

context(@"sync blocks", ^{
  it(@"should execute block", ^{
    __block BOOL ranBlock = NO;

    [queue runSyncIfNotPaused:^{
      ranBlock = YES;
    }];

    expect(ranBlock).to.beTruthy();
  });

  it(@"should execute recursive blocks", ^{
    __block BOOL ranBlock = NO;

    [queue runSyncIfNotPaused:^{
      [queue runSyncIfNotPaused:^{
        ranBlock = YES;
      }];
    }];

    expect(ranBlock).to.beTruthy();
  });
});

context(@"pause and resume", ^{
  beforeEach(^{
    queue.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    queue.failureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  });

  it(@"should support pausing", ^{
    __block BOOL paused = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue pauseWithCompletion:^{
      paused = YES;
      dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(queue.isPaused).to.beTruthy();
    expect(paused).to.beTruthy();
  });

  it(@"should support resuming", ^{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue pauseWithCompletion:^{
      [queue resume];
      dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(queue.isPaused).to.beFalsy();
  });

  it(@"should not execute pending tasks after pausing", ^{
    __block BOOL ranFirstTask = NO;
    __block BOOL ranSecondTask = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue runAsync:^{
      ranFirstTask = YES;
    } completion:^{
      [queue pauseWithCompletion:^{
        [queue runAsync:^{
          ranSecondTask = YES;
        } completion:nil];
        
        dispatch_semaphore_signal(semaphore);
      }];
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(ranFirstTask).to.beTruthy();
    expect(ranSecondTask).to.beFalsy();
  });

  it(@"should execute pending task when resuming", ^{
    __block BOOL ranTask = NO;

    dispatch_semaphore_t pauseSemaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_t taskSemaphore = dispatch_semaphore_create(0);

    [queue pauseWithCompletion:^{
      [queue runAsync:^{
        ranTask = YES;
      } completion:^{
        dispatch_semaphore_signal(taskSemaphore);
      }];

      dispatch_semaphore_signal(pauseSemaphore);
    }];

    dispatch_semaphore_wait(pauseSemaphore, semaphoreWaitTime);

    expect(ranTask).to.beFalsy();

    [queue resume];
    dispatch_semaphore_wait(taskSemaphore, semaphoreWaitTime);

    expect(ranTask).to.beTruthy();
  });
});

context(@"callback queues", ^{
  it(@"should have a default value", ^{
    expect(queue.completionQueue).to.equal(dispatch_get_main_queue());
    expect(queue.failureQueue).to.equal(dispatch_get_main_queue());
  });
});

context(@"opengl", ^{
  beforeEach(^{
    queue.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    queue.failureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  });

  it(@"should have valid opengl context for sync blocks", ^{
    __block EAGLContext *context;

    [queue runSyncIfNotPaused:^{
      context = [EAGLContext currentContext];
    }];

    expect(context).toNot.beNil();
  });

  it(@"should have valid opengl context for async blocks", ^AsyncBlock {
    __block EAGLContext *context;

    [queue runAsync:^{
      context = [EAGLContext currentContext];
    } completion:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        expect(context).toNot.beNil();
        done();
      });
    }];
  });
});

context(@"failure handling", ^{
  __block BOOL calledErrorHandler;

  beforeEach(^{
    calledErrorHandler = NO;

    [queue setErrorHandler:^(NSError __unused *error) {
      calledErrorHandler = YES;
    }];
  });

  context(@"sync", ^{
    it(@"should call error handler when no failure block is specified", ^{
      [queue runSyncIfNotPaused:^{
        [LTGLException raise:@"MyError" format:@"description"];
      }];

      expect(calledErrorHandler).to.beTruthy();
    });

    it(@"should call error handler when failure block returns no", ^{
      [queue runSyncIfNotPaused:^{
        [LTGLException raise:@"MyError" format:@"description"];
      } failure:^BOOL(NSError __unused *error) {
        return NO;
      }];

      expect(calledErrorHandler).to.beTruthy();
    });

    it(@"should not call error handler when failure block returns yes", ^{
      [queue runSyncIfNotPaused:^{
        [LTGLException raise:@"MyError" format:@"description"];
      } failure:^BOOL(NSError __unused *error) {
        return YES;
      }];

      expect(calledErrorHandler).to.beFalsy();
    });
  });

  context(@"async", ^{
    __block dispatch_semaphore_t semaphore;

    beforeEach(^{
      queue.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      queue.failureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

      semaphore = dispatch_semaphore_create(0);

      [queue setErrorHandler:^(NSError __unused *error) {
        calledErrorHandler = YES;
        dispatch_semaphore_signal(semaphore);
      }];
    });

    it(@"should call error handler when no failure block is specified", ^{
      [queue runAsync:^{
        [LTGLException raise:@"MyError" format:@"description"];
      } completion:nil];

      dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

      expect(calledErrorHandler).to.beTruthy();
    });

    it(@"should call error handler when failure block returns no", ^{
      [queue runAsync:^{
        [LTGLException raise:@"MyError" format:@"description"];
      } completion:nil failure:^BOOL(NSError __unused *error) {
        return NO;
      }];

      dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

      expect(calledErrorHandler).to.beTruthy();
    });

    it(@"should not call error handler when failure block returns yes", ^{
      [queue runAsync:^{
        [LTGLException raise:@"MyError" format:@"description"];
      } completion:nil failure:^BOOL(NSError __unused *error) {
        dispatch_semaphore_signal(semaphore);
        return YES;
      }];

      dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

      expect(calledErrorHandler).to.beFalsy();
    });
  });
});

SpecEnd
