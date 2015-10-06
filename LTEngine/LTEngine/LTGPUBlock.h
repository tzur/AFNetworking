// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Convenience methods for executing GPU-related blocks in various scenarios.

/// Executes the given block immediately if the app is in foreground, or delays execution until the
/// app returns to foreground. This method should be called from the main thread only.
///
/// Sample code:
/// @code
/// LTGPUBlock(^{
///   ...
/// });
/// @endcode
void LTGPUBlock(LTVoidBlock block);

/// Executes the given returned block upon completion, or delays until the app returns to foreground
/// for execution. This method should be called from the main thread only.
///
/// Sample code:
/// @code
/// [self doSomethingWithCompletion:LTGPUCompletion(^{
///   ...
/// })];
/// @endcode
LTCompletionBlock LTGPUCompletion(LTCompletionBlock block);
