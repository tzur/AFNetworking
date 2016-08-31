// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c NSNotificationCenter for testing purposes. Counts the number of currently connected
/// observers.
///
/// @note \c removeObserver called during the observer's \c dealloc method, will not affect
/// \c currentlyConnectedObserverCount.
///
/// @note This object doesn't support asynchronous operations. The
/// \c addObserverForName:object:queue:usingBlock: method ignores \c queue.
@interface CUIFakeNSNotificationCenter : NSNotificationCenter

/// Number of currently connected observers.
///
/// @note \c removeObserver called during the observer's \c dealloc method, will not decrease
/// \c currentlyConnectedObserverCount (\c CUIFakeNSNotificationCenter has no way of knowing that
/// \c removeObserver was called with the correct observer since ARC runtime returns \c nil for a
/// weak object during the \c dealloc method. \c nil values).
- (NSUInteger)currentlyConnectedObserverCount;

@end

NS_ASSUME_NONNULL_END
