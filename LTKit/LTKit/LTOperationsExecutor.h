// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Class which collects \c NSOperation objects and executes them serially if execution is allowed.
@interface LTOperationsExecutor : NSObject

/// Adds the given \c operation to the list of operations to execute when \c executionAllowed is \c
/// YES. The \c operation cannot be \c nil.
- (void)addOperation:(NSOperation *)operation;

/// Removes the given \c operation from the list of operations to execute when \c executionAllowed
/// is \c YES. The \c operation cannot be \c nil.
- (void)removeOperation:(NSOperation *)operation;

/// Executes all the stored operations in the order of their addition, and cleans the list
/// afterwards. If \c executionAllowed is \c NO, nothing will be done.
- (void)executeAll;

/// If \c YES, foreground operations can be executed.
@property (nonatomic) BOOL executionAllowed;

@end
