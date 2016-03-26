// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSpectaOpenGLContextHook.h"

#import <LTEngine/LTGLContext.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LTSpectaOpenGLContextHook

+ (void)beforeEach {
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
}

+ (void)afterEach {
  [LTGLContext setCurrentContext:nil];
}

@end

NS_ASSUME_NONNULL_END
