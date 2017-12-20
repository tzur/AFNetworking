// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Copies the data of a Metal texture at \c slice and returns it as a \c cv::Mat.
///
/// @note only textures with uncompressed 4-channel pixel formats are supported (RGBA 8, 16 or 32
/// bit) with the exception of unsigned int 32-bit per channel which is not supported. \c texture
/// bytes are explicitly copied into the returned mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
cv::Mat PNKMatFromMTLTexture(id<MTLTexture> texture, NSUInteger slice = 0);

/// Copies \c region of a \c slice of a Metal texture and returns it as a \c cv::Mat.
///
/// @note Textures with uncompressed 1, 2 and 4-channel pixel formats are supported (R/RG/RGBA
/// 8/16/32 bit) with the exception of unsigned int 32-bit per channel which is not supported.
/// \c texture bytes are explicitly copied into the returned mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
cv::Mat PNKMatFromMTLTextureRegion(id<MTLTexture> texture, MTLRegion region, NSUInteger slice = 0);

/// Copies the data of a Metal texture at \c slice to the provided \c mat.
///
/// @note Textures with uncompressed 1, 2 and 4-channel pixel formats are supported (R/RG/RGBA
/// 8/16/32 bit) with the exception of unsigned int 32-bit per channel which is not supported.
/// \c texture bytes are explicitly copied into the provided \c mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
void PNKCopyMTLTextureToMat(id<MTLTexture> texture, NSUInteger slice, NSUInteger mipmapLevel,
                            cv::Mat *mat);

/// Copies \c region of a \c slice of a Metal texture to the provided \c mat.
///
/// @note Textures with uncompressed 1, 2 and 4-channel pixel formats are supported (R/RG/RGBA
/// 8/16/32 bit) with the exception of unsigned int 32-bit per channel which is not supported.
/// \c texture bytes are explicitly copied into the provided \c mat.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
void PNKCopyMTLTextureRegionToMat(id<MTLTexture> texture, MTLRegion region, NSUInteger slice,
                                  NSUInteger mipmapLevel, cv::Mat *mat);

/// Copies the content of \c data to \c region in \c texture at the given \c slice and
/// \c mipmapLevel.
///
/// @note only textures with 1, 2 or 4 channels with 8, 16 or 32 bits per channel pixel formats are
/// supported. An exception is raised if \c data is not continuous or if \c data size is not equal
/// to \c region size and \c data type doesn't match \c texture pixel format.
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
/// @note only textures with 1, 2 or 4 channels with 8, 16 or 32 bits per channel pixel formats are
/// supported. An exception is raised if \c data is not continuous or if \c data size is not equal
/// \c texture size and \c data type doesn't match \c texture pixel format.
///
/// @important one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
void PNKCopyMatToMTLTexture(id<MTLTexture> texture, const cv::Mat &data, NSUInteger slice = 0,
                            NSUInteger mipmapLevel = 0);

NS_ASSUME_NONNULL_END
