// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for handlers of \c -application:openURL:options:, enabling handling of requests through
/// the OpenURL mechanism.
@protocol PTNOpenURLHandler <NSObject>

/// Triggers an event specified by \c url, and provides \c options as a dictionary of launch
/// options. Returns \c YES if the receiver successfully handled the event.
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(nullable NSDictionary<NSString *, id> *)options;

@end

NS_ASSUME_NONNULL_END
