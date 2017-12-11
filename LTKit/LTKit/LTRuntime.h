// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Returns \c YES if tests are currently running or planned to be injected in the current execution
/// of the app.
BOOL LTIsRunningTests();

/// Returns \c YES if the current execution of the app was launched with the given \c argument.
BOOL LTIsLaunchedWithArgument(NSString *argument);

NS_ASSUME_NONNULL_END
