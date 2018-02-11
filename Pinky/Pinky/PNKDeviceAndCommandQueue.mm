// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDeviceAndCommandQueue.h"

NS_ASSUME_NONNULL_BEGIN

id<MTLDevice> PNKDefaultDevice() {
  static id<MTLDevice> pnkDevice;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pnkDevice = MTLCreateSystemDefaultDevice();
  });
  return pnkDevice;
}

id<MTLCommandQueue> PNKDefaultCommandQueue() {
  static id<MTLCommandQueue> pnkCommandQueue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pnkCommandQueue = [PNKDefaultDevice() newCommandQueue];
  });
  return pnkCommandQueue;
}

NS_ASSUME_NONNULL_END
