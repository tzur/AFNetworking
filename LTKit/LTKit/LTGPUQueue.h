// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// @class LTGPUQueue.
///
/// Serial queue for GPU operations. All tasks submitted to this queue will use the same OpenGL
/// context, and since the queue is serial there are no concurrency issues with dispatching multiple
/// operations to the queue.
///
/// Blocks can be dispatched to the queue synchronously and
/// asynchronously, with the limitation that synchronous dispatching request can be discarded if the
/// queue is paused to avoid deadlocks.
///
/// On destruction, the queue will resume itself if paused and
/// execute all remaining tasks before proceeding.
///
/// This class is thread-safe.
@interface LTGPUQueue : NSObject

/// Returns the shared, singleton GPU queue.
+ (instancetype)sharedQueue;

#pragma mark -
#pragma mark Block dispatching
#pragma mark -

/// Block prototype for failure blocks. If the returned value is \c YES, error handling should stop
/// propagating.
typedef BOOL (^LTGPUQueueFailureBlock)(NSError *error);

/// Executes the given block on a queue asynchronously. The block is guaranteed to have a valid
/// OpenGL context present.
///
/// @param block block to execute asynchronously. Cannot be \c nil.
/// @param completion block that is called after the block finished executing. Will be called on the
/// \c completionQueue queue.
/// @param failure block that is called if an \c LTGLException has been raised while executing the
/// block. If the result of the block is \c YES, the error is considered as handled. Otherwise, the
/// queue's registered error handler will be called instead. Will be called on the \c errorQueue
/// queue.
///
/// @note only one of the result blocks, \c completion or \c error, will be called.
- (void)runAsync:(LTVoidBlock)block completion:(LTCompletionBlock)completion
         failure:(LTGPUQueueFailureBlock)failure;

/// Executes the given block on a queue asynchronously. The block is guaranteed to have a valid
/// OpenGL context present.
///
/// @param block block to execute asynchronously. Cannot be \c nil.
/// @param completion block that is called after the block completed successfully. Will be called on
/// the \c completionQueue queue.
///
/// @note use \c registerErrorHandler: to register a global error handler for the queue, which will
/// be called on error.
- (void)runAsync:(LTVoidBlock)block completion:(LTCompletionBlock)completion;

/// Executes the given block on a queue synchronously, if not paused. The block is guaranteed to
/// have a valid OpenGL context present.  If the queue is currently paused, the block will not run
/// (to protect from a deadlock).
///
/// @param block block to execute synchronously. Cannot be \c nil.
/// @param failure block that is called if an \c LTGLException has been raised while executing the
/// block. If the result of the block is \c YES, the error is considered as handled. Otherwise, the
/// queue's registered error handler will be called instead. Will be called on the same queue that
/// this method was called from.
///
/// @return \c YES if the block executed, or \c NO if the queue is currently paused and the call was
/// ignored.
- (BOOL)runSyncIfNotPaused:(LTVoidBlock)block failure:(LTGPUQueueFailureBlock)failure;

/// Executes the given block on a queue synchronously, if not paused. The block is guaranteed to
/// have a valid OpenGL context present.  If the queue is currently paused, the block will not run
/// (to protect from a deadlock).
///
/// @param block block to execute synchronously. Cannot be \c nil.
///
/// @return \c YES if the block executed, or \c NO if the queue is currently paused and the call was
/// ignored.
- (BOOL)runSyncIfNotPaused:(LTVoidBlock)block;

#pragma mark -
#pragma mark Flow control
#pragma mark -

/// Pauses the queue. This is not an immediate process, and will take effect only after the current
/// executing block and all queued synchonous blocks will be finish executing.
///
/// @param completion completion block to call once the queue is paused. Any dispatches made after
/// this block has been called will not run until the corresponding \c resume message is sent.
- (void)pauseWithCompletion:(LTCompletionBlock)completion;

/// Resumes the queue. Any pending tasks will start executing immediately.
- (void)resume;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Queue's error handler. The handler will be called in the following scenarios:
///
/// - A block that raised an error has been queued with a method that doesn't supply an error
/// handler (including methods that were given a \nil error handler).
///
/// - A block that raised an error has been queued with a method that does supply an error handler,
/// and that handler returned \c NO.
///
/// The handler is called on the provided \c errorQueue.
@property (copy, atomic) LTFailureBlock errorHandler;

/// Queue to dispatch completion blocks to. By default, this is set to the main queue.
@property (strong, atomic) dispatch_queue_t completionQueue;

/// Queue to dispatch failure blocks to. By default, this is set to the main queue.
@property (strong, atomic) dispatch_queue_t failureQueue;

/// \c YES if the queue is currently paused.
@property (readonly, atomic) BOOL isPaused;

@end
