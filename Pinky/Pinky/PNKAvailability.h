// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Determines whether the Metal Performance Shaders framework supports a Metal device.
BOOL PNKSupportsMTLDevice(id<MTLDevice> device);

#endif

NS_ASSUME_NONNULL_END
