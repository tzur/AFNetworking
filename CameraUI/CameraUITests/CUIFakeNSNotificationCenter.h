// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c NSNotificationCenter for testing purposes. Counts the number of currently connected
/// observers.
///
/// @note This object doesn't support asynchronous operations. The
/// \c addObserverForName:object:queue:usingBlock: method ignores \c queue.
@interface CUIFakeNSNotificationCenter : NSNotificationCenter
- (NSUInteger)currentlyConnectedObserverCount;
@end

NS_ASSUME_NONNULL_END
