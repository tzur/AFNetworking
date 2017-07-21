// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Creates a new \c MPSImage for use on \c device with the given \c format and given \c width,
/// \c height and \c channels.
MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels);

/// Creates a new \c MPSImage for use on \c device with \c MPSImageFeatureChannelFormatUnorm8 as the
/// channel format and given \c width, \c height and \c channels.
MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels);

NS_ASSUME_NONNULL_END
