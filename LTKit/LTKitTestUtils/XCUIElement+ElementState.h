// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Category for querying the state of the element.
@interface XCUIElement (ElementState)

/// Waits until the given \c timeout for the element's \c hittable property to become \c YES.
/// Returns \c NO if the timeout expires without the element becoming hittable.
- (BOOL)lt_waitForHittabilityWithTimeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
