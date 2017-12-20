// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Asserts that the \c pixelBuffer has one of supported pixel formats. Currently supported pixel
/// formats are 1- and 4-channels non-planar formats with either uchar or half-float channels.
void PNKAssertPixelBufferFormat(CVPixelBufferRef pixelBuffer);

/// Creates a Metal texture wrapper of the \c pixelBuffer for use with \c device and returns it to
/// the caller. \c pixelBuffer must have one of supported pixel formats. Currently supported pixel
/// formats are 1- and 4-channels non-planar formats with either uchar or half-float channels.
///
/// @important This function does not have any synchronization mechanisms whatsoever. The
/// synchronization of reading/writing the \c pixelBuffer from the CPU side and reading/writing
/// the Metal texture wrapper from the GPU side are the caller's responsibility.
id<MTLTexture> PNKTextureFromPixelBuffer(CVPixelBufferRef pixelBuffer, id<MTLDevice> device);

#endif

NS_ASSUME_NONNULL_END
