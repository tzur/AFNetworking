// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Specta/SPTGlobalBeforeAfterEach.h>

NS_ASSUME_NONNULL_BEGIN

/// Specta hook which creates an LTGLContext and sets it as the current context, and tears it up
/// when the spec ends.
@interface LTSpectaOpenGLContextHook : NSObject <SPTGlobalBeforeAfterEach>
@end

NS_ASSUME_NONNULL_END
