// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTOperationsExecutor;

/// Implements an operation that runs only when the app is in foreground. Asynchronous operations
/// such as callback blocks can be executed in the following scenarios:
///
/// 1. After \c applicationDidEnterBackground: completed and before the app finished executing all
///    the messages in the main queue.
/// 2. After the app returned to foreground and before \c applicationWillEnterForeground: started.
/// 3. After the app returned to foreground and before \c applicationWillEnterForeground: completed.
/// 4. After the app returned to foreground and after \c applicationWillEnterForeground: completed.
///
/// While most of the operations can run seamlessly on scenarios 1-3, there are two exceptions:
/// 1. OpenGL execution is prohibited while running in background (scenario 1).
/// 2. Handling objects which are paged-out manually by code that runs in \c didEnterBackground:
///    will produce invalid results.
///
/// \c LTForegroundOperation can be nested one inside the other.
@interface LTForegroundOperation : NSBlockOperation

/// Executor associated with foreground operations.
+ (LTOperationsExecutor *)executor;

/// Returns a forground block that wraps the original block and verifies that the app is in
/// background before calling it.
@property (readonly, nonatomic) LTCompletionBlock foregroundBlock;

@end
