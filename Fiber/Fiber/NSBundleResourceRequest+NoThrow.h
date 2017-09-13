// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Category wrapping the \c NSBundleResourceRequest functionality with try-catch in order to avoid
/// exceptions being raised.
/// @see https://openradar.appspot.com/34389684
@interface NSBundleResourceRequest (NoThrow)

/// Wraps \c beginAccessingResourcesWithCompletionHandler. In case an exception is raised,
/// \c completionHandler will be invoked on a non-main serial queue with \c error set to
/// \c LTErrorCodeExceptionRaised.
- (void)fbr_beginAccessingResourcesWithCompletionHandler:
    (void (^)(NSError * _Nullable error))completionHandler;

/// Wraps \c conditionallyBeginAccessingResourcesWithCompletionHandler. In case an exception is
/// raised, \c completionHandler will be invoked on a non-main serial queue with
/// \c resourcesAvailable set to \c NO.
- (void)fbr_conditionallyBeginAccessingResourcesWithCompletionHandler:
    (void (^)(BOOL resourcesAvailable))completionHandler;

@end

NS_ASSUME_NONNULL_END
