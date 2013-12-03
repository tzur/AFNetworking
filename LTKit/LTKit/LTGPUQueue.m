// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUQueue.h"

#import "LTGLException.h"

@interface LTGPUQueue ()

/// Low priority queue, where blocks are dispatched to.
@property (strong, nonatomic) dispatch_queue_t lowPriorityQueue;

/// High priority queue for management tasks such as queue suspension.
@property (strong, nonatomic) dispatch_queue_t highPriorityQueue;

/// Dispatch group for all currently running tasks.
@property (strong, nonatomic) dispatch_group_t group;

/// OpenGL context that is used on given blocks.
@property (strong, nonatomic) EAGLContext *context;

/// \c YES if the queue is currently paused.
@property (readwrite, atomic) BOOL isPaused;

@end

/// Key associated with the low priority queue.
static void *kLTGPULowPriorityQueueKey = &kLTGPULowPriorityQueueKey;

/// Key associated with the high priority queue.
static void *kLTGPUHighPriorityQueueKey = &kLTGPUHighPriorityQueueKey;

@implementation LTGPUQueue

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)init {
  if (self = [super init]) {
    [self createQueues];
    [self createOpenGLContext];

    self.group = dispatch_group_create();
    self.completionQueue = dispatch_get_main_queue();
    self.failureQueue = dispatch_get_main_queue();
  }
  return self;
}

- (void)dealloc {
  // Releasing a suspended dispatch queue will result in an exception.
  [self resume];

  // Wait until all the tasks finished executing.
  dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER);
}

- (void)createQueues {
  // Low priority queue -> high priority queue.
  self.lowPriorityQueue = dispatch_queue_create("com.lightricks.LTKit.GPUQueue-lowpri",
                                                DISPATCH_QUEUE_SERIAL);
  self.highPriorityQueue = dispatch_queue_create("com.lightricks.LTKit.GPUQueue-highpri",
                                                 DISPATCH_QUEUE_SERIAL);
  dispatch_set_target_queue(self.lowPriorityQueue, self.highPriorityQueue);

  // Set a custom key for this queue. This will allow to querying if the code is executing on this
  // queue or not (to avoid using the deprecated \c dispatch_get_current_queue()).
  dispatch_queue_set_specific(self.lowPriorityQueue, kLTGPULowPriorityQueueKey,
                              (__bridge void *)(self), NULL);
  dispatch_queue_set_specific(self.highPriorityQueue, kLTGPUHighPriorityQueueKey,
                              (__bridge void *)(self), NULL);
}

- (void)createOpenGLContext {
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  if (!self.context) {
    [LTGLException raise:kLTGPUQueueContextCreationFailedException
                  format:@"Failed creating OpenGL ES context"];
  }
}

- (void)useContext {
  if ([EAGLContext currentContext] != self.context) {
    if (![EAGLContext setCurrentContext:self.context]) {
      [LTGLException raise:kLTGPUQueueContextSetFailedException
                    format:@"Failed to set context to current thread"];
    }
  }
}

#pragma mark -
#pragma mark Async dispatching
#pragma mark -

- (void)runAsync:(LTVoidBlock)block completion:(LTCompletionBlock)completion
         failure:(LTGPUQueueFailureBlock)failure {
  NSParameterAssert(block);

  @synchronized(self) {
    if (dispatch_get_specific(kLTGPULowPriorityQueueKey)) {
      dispatch_group_enter(self.group);
      [self executeAsyncBlock:block completion:completion failure:failure];
      dispatch_group_leave(self.group);
    } else {
      dispatch_group_async(self.group, self.lowPriorityQueue, ^{
        [self executeAsyncBlock:block completion:completion failure:failure];
      });
    }
  }
}

- (void)runAsync:(LTVoidBlock)block completion:(LTCompletionBlock)completion {
  [self runAsync:block completion:completion failure:nil];
}

- (void)executeAsyncBlock:(LTVoidBlock)block completion:(LTCompletionBlock)completion
                  failure:(LTGPUQueueFailureBlock)failure {
  [self useContext];

  @try {
    block();
  } @catch (LTGLException *exception) {
    LogError(@"Encountered LTGLException while running on the GPU Queue: %@",
             exception.description);
    [self handleAsyncError:[NSError errorWithLTGLException:exception] failure:failure];
    return;
  }

  if (completion) {
    dispatch_async(self.completionQueue, ^{
      completion();
    });
  }
}

- (void)handleAsyncError:(NSError *)error failure:(LTGPUQueueFailureBlock)failure {
  if (failure) {
    dispatch_async(self.failureQueue, ^{
      if (!failure(error)) {
        [self sendErrorToErrorHandler:error];
      }
    });
  } else {
    dispatch_async(self.failureQueue, ^{
      [self sendErrorToErrorHandler:error];
    });
  }
}

#pragma mark -
#pragma mark Sync dispatching
#pragma mark -

- (BOOL)runSyncIfNotPaused:(LTVoidBlock)block failure:(LTGPUQueueFailureBlock)failure {
  NSParameterAssert(block);

  @synchronized(self) {
    if (self.isPaused) {
      return NO;
    }

    // Since there's no dispatch_group_sync, simulate task enqueuing to the dispatch group.
    dispatch_group_enter(self.group);

    __block NSError *error = nil;

    if (dispatch_get_specific(kLTGPULowPriorityQueueKey)) {
      [self executeSyncBlock:block error:&error];
    } else {
      dispatch_sync(self.lowPriorityQueue, ^{
        [self executeSyncBlock:block error:&error];
      });
    }

    dispatch_group_leave(self.group);

    [self handleSyncError:error failure:failure];

    return YES;
  }
}

- (BOOL)runSyncIfNotPaused:(LTVoidBlock)block {
  return [self runSyncIfNotPaused:block failure:nil];
}

- (BOOL)executeSyncBlock:(LTVoidBlock)block error:(NSError **)error {
  [self useContext];

  @try {
    block();
  } @catch (LTGLException *exception) {
    LogError(@"Encountered LTGLException while running on the GPU Queue: %@",
             exception.description);
    *error = [NSError errorWithLTGLException:exception];
  }

  return !*error;
}

- (void)handleSyncError:(NSError *)error failure:(LTGPUQueueFailureBlock)failure {
  if (failure) {
    if (!failure(error)) {
      [self sendErrorToErrorHandler:error];
    }
  } else {
    [self sendErrorToErrorHandler:error];
  }
}

#pragma mark -
#pragma mark Flow control
#pragma mark -

- (void)pauseWithCompletion:(LTCompletionBlock)completion {
  @synchronized(self) {
    if (self.isPaused) {
      return;
    }

    dispatch_async(self.highPriorityQueue, ^{
      dispatch_suspend(self.highPriorityQueue);

      self.isPaused = YES;

      if (completion) {
        dispatch_async(self.completionQueue, ^{
          completion();
        });
      }
    });
  }
}

- (void)resume {
  @synchronized(self) {
    if (!self.isPaused) {
      return;
    }

    dispatch_resume(self.highPriorityQueue);
    self.isPaused = NO;
  }
}

#pragma mark -
#pragma mark Error handling
#pragma mark -

- (void)sendErrorToErrorHandler:(NSError *)error {
  if (self.errorHandler) {
    self.errorHandler(error);
  }
}

@end
