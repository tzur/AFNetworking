// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Calls the given \c block when a UIKit method is not called on the main thread. This is
/// implemented by swizzling \c setNeedsLayout, \c setNeedsDisplay, \c setNeedsDisplayInRect: since
/// a lot of UIKit calls internally call these methods. As such, it will not catch all of the
/// errors, but it covers most of them.
///
/// The recommended usage pattern is to call this method once on the app's startup, and log or
/// assert in the given \c block. This method is not intended to run in production.
///
/// Since the installation is global and involves hooks, subsequent calls to this methods will yield
/// a warning and return \c NO.
///
/// Returns \c YES if the installation was successful.
BOOL LTInstallUIKitMainThreadGuard(LTVoidBlock block);

NS_ASSUME_NONNULL_END
