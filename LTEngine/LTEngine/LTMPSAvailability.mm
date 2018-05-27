// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTMPSAvailability.h"

NS_ASSUME_NONNULL_BEGIN

#if LT_USE_MPS

BOOL LTMTLDeviceSupportsMPS(id<MTLDevice> device) {
  if (@available(iOS 10.0, *)) {
    return MPSSupportsMTLDevice(device);
  } else {
    return NO;
  }
}

#else

BOOL LTMTLDeviceSupportsMPS(id<MTLDevice> __unused device) {
  return NO;
}

#endif

NS_ASSUME_NONNULL_END
