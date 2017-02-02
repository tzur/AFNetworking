// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUQueue.h"

#import "LTGLContext.h"
#import "LTGLException.h"

@interface LTGPUQueue ()

/// Low priority queue, where blocks are dispatched to.
@property (strong, nonatomic) dispatch_queue_t lowPriorityQueue;

/// High priority queue for management tasks such as queue suspension.
@property (strong, nonatomic) dispatch_queue_t highPriorityQueue;

/// OpenGL context that is used on given blocks.
@property (strong, nonatomic) LTGLContext *context;

/// \c YES if the queue is currently paused.
@property (readwrite, atomic) BOOL isPaused;

@end

/// Key associated with the low priority queue.
static void *kLTGPULowPriorityQueueKey = &kLTGPULowPriorityQueueKey;

/// Key associated with the high priority queue.
static void *kLTGPUHighPriorityQueueKey = &kLTGPUHighPriorityQueueKey;

@implementation LTGPUQueue

objection_register_singleton([LTGPUQueue class]);

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithSharedContext:nil];
}

- (instancetype)initWithSharedContext:(LTGLContext *)context {
  if (self = [super init]) {
    [self createQueues];
    [self createOpenGLContextWithSharegroup:context.context.sharegroup];

    self.completionQueue = dispatch_get_main_queue();
    self.failureQueue = dispatch_get_main_queue();
  }
  return self;
}

- (void)dealloc {
  // Releasing a suspended dispatch queue will result in an exception.
  [self resume];
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

- (void)createOpenGLContextWithSharegroup:(EAGLSharegroup *)sharegroup {
  self.context = [[LTGLContext alloc] initWithSharegroup:sharegroup];
  if (!self.context) {
    [LTGLException raise:kLTGPUQueueContextCreationFailedException
                  format:@"Failed creating OpenGL ES context"];
  }
}

#pragma mark -
#pragma mark Singleton
#pragma mark -

+ (instancetype)sharedQueue {
  static LTGPUQueue *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTGPUQueue alloc] init];
  });

  return instance;
}

#pragma mark -
#pragma mark Async dispatching
#pragma mark -

- (void)runAsync:(LTVoidBlock)block completion:(LTCompletionBlock)completion
         failure:(LTGPUQueueFailureBlock)failure {
  LTParameterAssert(block);

  @synchronized(self) {
    if (dispatch_get_specific(kLTGPULowPriorityQueueKey)) {
      [self executeAsyncBlock:block completion:completion failure:failure];
    } else {
      dispatch_async(self.lowPriorityQueue, ^{
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
  LTGLContext *previousContext = [self useContext];

  @try {
    [self executeBlock:block];
  } @catch (LTGLException *exception) {
    LogError(@"Encountered LTGLException while running on the GPU Queue: %@",
             exception.description);
    [self handleAsyncError:[NSError lt_errorWithLTGLException:exception] failure:failure];
    return;
  } @finally {
    [self restoreContext:previousContext];
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
  LTParameterAssert(block);

  @synchronized(self) {
    if (self.isPaused) {
      return NO;
    }

    __block NSError *error = nil;

    if (dispatch_get_specific(kLTGPULowPriorityQueueKey)) {
      [self executeSyncBlock:block error:&error];
    } else {
      dispatch_sync(self.lowPriorityQueue, ^{
        [self executeSyncBlock:block error:&error];
      });
    }

    if (error) {
      [self handleSyncError:error failure:failure];
    }

    return YES;
  }
}

- (BOOL)runSyncIfNotPaused:(LTVoidBlock)block {
  return [self runSyncIfNotPaused:block failure:nil];
}

- (BOOL)executeSyncBlock:(LTVoidBlock)block error:(NSError *__autoreleasing *)error {
  LTGLContext *previousContext = [self useContext];

  @try {
    [self executeBlock:block];
  } @catch (LTGLException *exception) {
    LogError(@"Encountered LTGLException while running on the GPU Queue: %@",
             exception.description);
    *error = [NSError lt_errorWithLTGLException:exception];
  } @finally {
    [self restoreContext:previousContext];
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
#pragma mark Execution
#pragma mark -

- (void)executeBlock:(LTVoidBlock)block {
  // GCD queues drain their autoreleasepools only when the GCD thread is idle, therefore objects may
  // be released after their context is unset, causing a crash. Wrapping the block with
  // @autoreleasepool enforces objects that are created in the block to deallocate after the block
  // ends. See session 718, WWDC 2015 for more details.
  @autoreleasepool {
    block();
  }
}

- (LTGLContext *)useContext {
  LTGLContext *previousContext = [LTGLContext currentContext];
  if (previousContext != self.context) {
    [LTGLContext setCurrentContext:self.context];
  }
  return previousContext;
}

- (void)restoreContext:(LTGLContext *)context {
  [LTGLContext setCurrentContext:context];
}

#pragma mark -
#pragma mark Flow control
#pragma mark -

- (void)pauseWhileBlocking {
  @synchronized(self) {
    if (self.isPaused) {
      return;
    }

    // Suspend the low priority queue. This will stop sending enqueued blocks from the low priority
    // queue to the high priority queue.
    dispatch_suspend(self.lowPriorityQueue);

    // Dispatch a suspending block to the high priority block. Once this block finishes execution,
    // no more blocks will be executing in the high priority queue. Since the high priority queue is
    // the target of the low priority queue, nothing will be executed on the queue until \c resume
    // is called.
    dispatch_sync(self.highPriorityQueue, ^{
      dispatch_suspend(self.highPriorityQueue);
      self.isPaused = YES;
    });
  }
}

- (void)resume {
  @synchronized(self) {
    if (!self.isPaused) {
      return;
    }

    dispatch_resume(self.lowPriorityQueue);
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
