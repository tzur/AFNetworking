// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// Creates a new pixel buffer with the given \c width, \c height, and pixel format. The pixel
/// buffer is compatible with \c LTMMTexture and could be used to create the latter.
///
/// Raises \c LTGLException if creation fails.
lt::Ref<CVPixelBufferRef> LTCVPixelBufferCreate(size_t width, size_t height,
                                                OSType pixelFormatType);

/// Locks the given \c pixelBuffer with \c lockFlags, and executes the given \c block.
/// \c pixelBuffer is unlocked before this function returns.
///
/// Raises \c LTGLException if locking or unlocking fails.
void LTCVPixelBufferLockAndExecute(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                                   NS_NOESCAPE LTVoidBlock block);

/// Block for reading pixels of a pixel buffer using \c cv::Mat.
///
/// @note \c image must not be used outside of the block.
typedef void (^LTCVPixelBufferReadBlock)(const cv::Mat &image);

/// Block for reading and writing pixels of a pixel buffer using \c cv::Mat.
///
/// @note \c image must not be used outside of the block.
typedef void (^LTCVPixelBufferWriteBlock)(cv::Mat *image);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of the given \c pixelBuffer.
/// The latter is properly locked and unlocked, with the given \c lockFlags.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note this function is suitable only for non-planar pixel buffers.
/// Use \c LTCVPixelBufferPlaneImage to access pixels of planar pixel buffers.
///
/// @note You must not modify pixels of the pixel buffer if it is being locked for reading
/// (using \c k kCVPixelBufferLock_ReadOnly flag).
void LTCVPixelBufferImage(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                          NS_NOESCAPE LTCVPixelBufferWriteBlock block);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of the given \c pixelBuffer.
/// The latter is properly locked and unlocked for reading.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note this function is suitable only for non-planar pixel buffers.
/// Use \c LTCVPixelBufferPlaneImageForReading to read pixels of planar pixel buffers.
///
/// @note You must not modify pixels of the pixel buffer.
void LTCVPixelBufferImageForReading(CVPixelBufferRef pixelBuffer,
                                    NS_NOESCAPE LTCVPixelBufferReadBlock block);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of the given \c pixelBuffer.
/// The latter is properly locked and unlocked for writing.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note this function is suitable only for non-planar pixel buffers.
/// Use \c LTCVPixelBufferPlaneImageForWriting to write pixels of planar pixel buffers.
void LTCVPixelBufferImageForWriting(CVPixelBufferRef pixelBuffer,
                                    NS_NOESCAPE LTCVPixelBufferWriteBlock block);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of a plane with index
/// \c planeIndex in the given planar \c pixelBuffer. The latter is properly locked and unlocked,
/// with the given \c lockFlags.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note this function is suitable only for planar pixel buffers. Use \c LTCVPixelBufferImage to
/// access pixels of non-planar pixel buffers.
///
/// @note You must not modify pixels of the pixel buffer if it is being locked for reading
/// (using \c kCVPixelBufferLock_ReadOnly flag).
void LTCVPixelBufferPlaneImage(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                               CVPixelBufferLockFlags lockFlags,
                               NS_NOESCAPE LTCVPixelBufferWriteBlock block);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of a plane with index
/// \c planeIndex in the given planar \c pixelBuffer. The latter is properly locked and unlocked for
/// reading.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note this function is suitable only for planar pixel buffers.
/// Use \c LTCVPixelBufferImageForReading to read pixels of non-planar pixel buffers.
///
/// @note You must not modify pixels of the pixel buffer.
void LTCVPixelBufferPlaneImageForReading(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                                         NS_NOESCAPE LTCVPixelBufferReadBlock block);

/// Executes the given \c block with a \c cv::Mat that wraps the pixels of a plane with index
/// \c planeIndex in the given planar \c pixelBuffer. The latter is properly locked and unlocked for
/// writing.
///
/// Raises \c LTGLException if locking or unlocking fails, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note this function is suitable only for planar pixel buffers.
/// Use \c LTCVPixelBufferImageForWriting to write pixels of non-planar pixel buffers.
void LTCVPixelBufferPlaneImageForWriting(CVPixelBufferRef pixelBuffer, size_t planeIndex,
                                         NS_NOESCAPE LTCVPixelBufferWriteBlock block);

/// Block for reading and writing pixels of a pixel buffer using \c cv::Mat. \c images is a vector
/// of matrices, each representing a single plane, at the same index. For non planar pixel buffers,
/// contains a single matrix.
///
/// @note \c images (and its matrices) must not be used outside of the block.
typedef void (^LTCVPixelBufferImagesBlock)(const std::vector<cv::Mat> &images);

/// Executes the given \c block with a vector of matrices, each wrapping the pixels of a plane with
/// the same index. For non planar pixel buffers, the vector contains a single matrix. The pixel
/// buffer is properly locked and unlocked, with the given \c lockFlags.
///
/// Raises \c LTGLException if locking or unlocking fails.
///
/// @note You must not modify pixels of the pixel buffer if it is being locked for reading
/// (using \c kCVPixelBufferLock_ReadOnly flag).
void LTCVPixelBufferImages(CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags,
                           NS_NOESCAPE LTCVPixelBufferImagesBlock block);

/// Executes the given \c block with a vector of matrices, each wrapping the pixels of a plane with
/// the same index. For non planar pixel buffers, the vector contains a single matrix. The pixel
/// buffer is properly locked and unlocked for reading.
///
/// Raises \c LTGLException if locking or unlocking fails.
///
/// @note You must not modify pixels of the pixel buffer.
void LTCVPixelBufferImagesForReading(CVPixelBufferRef pixelBuffer,
                                     NS_NOESCAPE LTCVPixelBufferImagesBlock block);

/// Executes the given \c block with a vector of matrices, each wrapping the pixels of a plane with
/// the same index. For non planar pixel buffers, the vector contains a single matrix. The pixel
/// buffer is properly locked and unlocked for writing.
///
/// Raises \c LTGLException if locking or unlocking fails.
void LTCVPixelBufferImagesForWriting(CVPixelBufferRef pixelBuffer,
                                     NS_NOESCAPE LTCVPixelBufferImagesBlock block);

NS_ASSUME_NONNULL_END
