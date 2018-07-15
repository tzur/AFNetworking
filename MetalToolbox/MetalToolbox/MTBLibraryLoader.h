// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Loads a Metal library for \c device from \c path. Raises \c NSInvalidArgumentException when
/// \c path does not point to a valid Metal library. Any library loaded with this function is stored
/// in a global cache to prevent consequent loads from storage. This function is thread safe.
id<MTLLibrary> MTBLoadLibrary(id<MTLDevice> device, NSString *path);

NS_ASSUME_NONNULL_END
