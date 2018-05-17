// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRProductsInfoProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// The use of this class is available only in debug mode.
#ifdef DEBUG

/// Products info provider that can be used when the app is in the debug mode. Proxies an underlying
/// provider and uses Milkshake to allow inspecting and overriding some of the subscription
/// properties in runtime.
@interface BZRTweaksProductsInfoProvider : NSObject <BZRProductsInfoProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an \c underlyingProvider used to read the original subscription info from the
/// device.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsInfoProvider>)underlyingProvider;

@end

#endif

NS_ASSUME_NONNULL_END
