// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Opaque class used to cache the state of \c PNKStyleTransferProcessor for an input image that was
/// processed when this state was created. Using this state with the processor allows removing
/// processing stages and shortening the processing time.
///
/// @note This class may hold large objects and textures mapped to GPU memory.
@interface PNKStyleTransferState : NSObject

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
