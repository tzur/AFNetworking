// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Wrapper for \c GLKView that promises OpenGL context-guarding on deallocation. When this view
/// is deallocated it captures the current OpenGL context, and makes sure it is restored after the
/// \c GLKView has completed its deallocation. This context guarding is required since in iOS 9 and
/// above the \c GLKView nullifies the OpenGL context on deallocation.
///
/// @note Do not use \c GLKView directly, it may result in an unexpected behavior due to the
/// volatility it introduces to OpenGL context.
@interface LTGLView : GLKView
@end

NS_ASSUME_NONNULL_END
