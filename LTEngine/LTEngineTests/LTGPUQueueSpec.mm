// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUQueue.h"

#import "LTGLContext.h"
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

  it(@"should deallocate objects created in the block", ^{
    __block __weak NSObject *weakObject = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue runAsync:^{
      NSObject *object = [[NSObject alloc] init];
      weakObject = object;
    } completion:^{
      dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(weakObject).to.beNil();
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

  it(@"should deallocate objects created in the block", ^{
    __block __weak NSObject *weakObject = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue runSyncIfNotPaused:^{
      NSObject *object = [[NSObject alloc] init];
      weakObject = object;

      dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(weakObject).to.beNil();
  });

  it(@"should not call error block on normal execution", ^{
    __block BOOL causedError = NO;

    [queue runSyncIfNotPaused:^{
    } failure:^BOOL(NSError __unused *error) {
      causedError = YES;
      return YES;
    }];

    expect(causedError).to.beFalsy();
  });

  it(@"should call error block on exception", ^{
    __block BOOL causedError = NO;

    [queue runSyncIfNotPaused:^{
      [LTGLException raise:@"MyError" format:@"description"];
    } failure:^BOOL(NSError __unused *error) {
      causedError = YES;
      return YES;
    }];

    expect(causedError).to.beTruthy();
  });
});

context(@"pause and resume", ^{
  beforeEach(^{
    queue.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    queue.failureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  });

  it(@"should support pausing", ^{
    [queue pauseWhileBlocking];

    expect(queue.isPaused).to.beTruthy();
  });

  it(@"should support resuming", ^{
    [queue pauseWhileBlocking];
    [queue resume];

    expect(queue.isPaused).to.beFalsy();
  });

  it(@"should not execute pending tasks after pausing", ^{
    __block BOOL ranFirstTask = NO;
    __block BOOL ranSecondTask = NO;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [queue runAsync:^{
      ranFirstTask = YES;
    } completion:^{
      [queue pauseWhileBlocking];
      [queue runAsync:^{
        ranSecondTask = YES;
      } completion:nil];

      dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, semaphoreWaitTime);

    expect(ranFirstTask).to.beTruthy();
    expect(ranSecondTask).to.beFalsy();
  });

  it(@"should execute pending task when resuming", ^{
    __block BOOL ranTask = NO;

    dispatch_semaphore_t taskSemaphore = dispatch_semaphore_create(0);

    [queue pauseWhileBlocking];
    [queue runAsync:^{
      ranTask = YES;
    } completion:^{
      dispatch_semaphore_signal(taskSemaphore);
    }];

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
    __block LTGLContext *context;

    [queue runSyncIfNotPaused:^{
      context = [LTGLContext currentContext];
    }];

    expect(context).toNot.beNil();
  });

  it(@"should have valid opengl context for async blocks", ^{
    waitUntil(^(DoneCallback done) {
      __block LTGLContext *context;

      [queue runAsync:^{
        context = [LTGLContext currentContext];
      } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
          expect(context).toNot.beNil();
          done();
        });
      }];
    });
  });

  it(@"should restore opengl context for sync blocks", ^{
    LTGLContext *context = [LTGLContext currentContext];

    [queue runSyncIfNotPaused:^{
    }];

    expect([LTGLContext currentContext]).to.equal(context);
  });

  it(@"should restore opengl context for async blocks", ^{
    waitUntil(^(DoneCallback done) {
      LTGLContext *context = [LTGLContext currentContext];

      [queue runAsync:^{
      } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
          expect([LTGLContext currentContext]).to.equal(context);
          done();
        });
      }];
    });
  });

  it(@"should restore nil opengl context for sync blocks", ^{
    [LTGLContext setCurrentContext:nil];

    [queue runSyncIfNotPaused:^{
    }];

    expect([LTGLContext currentContext]).to.beNil();
  });

  it(@"should restore nil opengl context for async blocks", ^{
    [LTGLContext setCurrentContext:nil];

    waitUntil(^(DoneCallback done) {
      [queue runAsync:^{
      } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
          expect([LTGLContext currentContext]).to.beNil();
          done();
        });
      }];
    });
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
