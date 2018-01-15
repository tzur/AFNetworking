// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKAvailability.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

BOOL PNKSupportsMTLDevice(id<MTLDevice> device) {
  return MPSSupportsMTLDevice(device);
}

#endif

NS_ASSUME_NONNULL_END
