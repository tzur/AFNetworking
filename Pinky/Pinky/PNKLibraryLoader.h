// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Loads the Pinky Metal library for \c device. This function is thread safe and performs
/// caching of the loaded libraries.
id<MTLLibrary> PNKLoadLibrary(id<MTLDevice> device);

NS_ASSUME_NONNULL_END
