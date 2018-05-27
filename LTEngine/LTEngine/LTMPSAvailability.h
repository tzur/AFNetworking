// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

// MetalPerformanceShaders doesn't exist on simulator targets.
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  #define LT_USE_MPS 1
#else
  #define LT_USE_MPS 0
#endif

@protocol MTLDevice;

/// Determines whether the Metal Performance Shaders framework supports a Metal device.
BOOL LTMTLDeviceSupportsMPS(id<MTLDevice> device);

NS_ASSUME_NONNULL_END
