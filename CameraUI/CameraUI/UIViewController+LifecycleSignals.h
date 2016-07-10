// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Category for managing a \c UIViewController lifecycle using signals.
@interface UIViewController (LifecycleSignals)

/// Returns a signal of \c BOOLs that sends \c YES when the receiver appears on screen or the app
/// returns from background and \c NO when it disappears from screen or the app enters background.
/// The returned signal listens to notifications from \c notificationCenter. The signal completes
/// when the receiver is deallocated. The values are distinct and sent on an arbitrary thread.
- (RACSignal *)cui_isVisibleWithNotificationCenter:(NSNotificationCenter *)notificationCenter;

/// Convenience method, same as calling \c cui_isVisibleWithNotificationCenter: using the default
/// \c NSNotificationCenter.
///
/// Returns a signal of \c BOOLs that sends \c YES when the receiver appears on screen or the app
/// returns from background and \c NO when it disappears from screen or the app enters background.
/// The returned signal listens to notifications from the default \c NSNotificationCenter. The
/// signal completes when the receiver is deallocated. The values are distinct and sent on an
/// arbitrary thread.
- (RACSignal *)cui_isVisible;

@end

NS_ASSUME_NONNULL_END
