// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Creates an \c MPSImage wrapper of the \c pixelBuffer for use with \c device and returns it to
/// the caller. \c pixelBuffer must have one of supported pixel formats. Currently supported pixel
/// formats are 1- and 4-channels non-planar formats with either uchar or half-float channels. The
/// wrapper image will have feature channels count equal to \c featureChannels. If
/// \c featureChannels is zero - the default channel count of the pixel buffer will be used.
///
/// @important This function does not have any synchronization mechanisms whatsoever. The
/// synchronization of reading/writing the \c pixelBuffer from the CPU side and reading/writing
/// the Metal texture wrapper from the GPU side are the caller's responsibility.
MPSImage *PNKImageFromPixelBuffer(CVPixelBufferRef pixelBuffer, id<MTLDevice> device,
                                  NSUInteger featureChannels = 0) API_AVAILABLE(ios(10.0));

NS_ASSUME_NONNULL_END
