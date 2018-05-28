// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTMTLDefaults.h"

NS_ASSUME_NONNULL_BEGIN

id<MTLDevice> LTMTLDefaultDevice() {
  static id<MTLDevice> device;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    device = MTLCreateSystemDefaultDevice();
  });
  return device;
}

id<MTLCommandQueue> LTMTLDefaultCommandQueue() {
  static id<MTLCommandQueue> commandQueue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    commandQueue = [LTMTLDefaultDevice() newCommandQueue];
  });
  return commandQueue;
}

NS_ASSUME_NONNULL_END
