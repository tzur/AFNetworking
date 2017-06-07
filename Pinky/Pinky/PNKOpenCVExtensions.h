// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Copies the data of a Metal texture and returns it as a \c cv::Mat.
///
/// @note only textures with uncompressed 4-channel pixel formats are supported (RGBA 8, 16 or 32
/// bit) with the exception of unsigned int 32-bit per channel which is not supported. \c texture
/// bytes are explicitly copied into the returned mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
cv::Mat PNKMatFromMTLTexture(id<MTLTexture> texture);

/// Copies \c region of \c data of a Metal texture and returns it as a \c cv::Mat.
///
/// @note only textures with uncompressed 4-channel pixel formats are supported (RGBA 8, 16 or 32
/// bit) with the exception of unsigned int 32-bit per channel which is not supported. \c texture
/// bytes are explicitly copied into the returned mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
cv::Mat PNKMatFromMTLTextureRegion(id<MTLTexture> texture, MTLRegion region);

/// Copies the content of \c data to \c region in \c texture at the given \c slice and
/// \c mipmapLevel.
///
/// @note only textures with uncompressed 4-channel pixel formats are supported (RGBA 8, 16 or 32
/// bit). An exception is raised if \c data is not continuous or if \c data size is not equal to
/// \c region size and \c data type doesn't match \c texture pixel format.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
///
/// For understanding \c slice see:
/// https://developer.apple.com/documentation/metalperformanceshaders/mpsimage
void PNKCopyMatToMTLTextureRegion(id<MTLTexture> texture, MTLRegion region, const cv::Mat &data,
                                  NSUInteger slice = 0, NSUInteger mipmapLevel = 0);

/// Copies the content of \c data to \c texture at the given \c slice and \c mipmapLevel.
///
/// @note only textures with uncompressed 4-channel pixel formats are supported (RGBA 8, 16 or 32
/// bit). An exception is raised if \c data is not continuous or if \c data size is not equal to
/// \c region size and \c data type doesn't match \c texture pixel format.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
void PNKCopyMatToMTLTexture(id<MTLTexture> texture, const cv::Mat &data, NSUInteger slice = 0,
                            NSUInteger mipmapLevel = 0);

NS_ASSUME_NONNULL_END
