// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

@class LTGLPixelFormat;

/// Pool of pixel buffers. The pool manages a set of pixel buffers for repeated use, potentially
/// saving allocation costs. All pixel buffers in the pool have the same format and dimension.
///
/// The pool does not have a fixed size. A new pixel buffer is allocated when a pixel buffer is
/// needed but no unused pixel buffer is available. It it possible to limit new allocations is such
/// cases, by using \c createPixelBufferNotExceedingMaximumBufferCount.
///
/// When a pixel buffer created by the pool is no longer used, it is automatically returned to the
/// pool for later use. Deallocations of unused pixel buffers are performed only when the pool is
/// explicitly flushed, or the pool itself is being deallocated.
///
/// @see CVPixelBufferPool which is the native object wrapped by this class.
@interface LTPixelBufferPool : NSObject

/// Initializes the pool of pixel buffers.
///
/// @param pixelFormat pixel format of all pixel buffers in the pool. Both planar and non-planar
/// formats are supported.
/// @param width width of each pixel buffer in the pool. Must be positive.
/// @param height height of each pixel buffer in the pool. Must be positive.
/// @param minimumBufferCount minimal number of pixel buffers to be immediately available in the
/// pool.
/// @param maximumBufferAge age of unused buffer, in seconds, before it can be deallocated by
/// calls to \c flushAged. \c 0 disables the aging mechanism.
///
/// Raises if the pool cannot be created.
- (instancetype)initWithPixelFormat:(OSType)pixelFormat
                              width:(size_t)width
                             height:(size_t)height
                 minimumBufferCount:(size_t)minimumBufferCount
                   maximumBufferAge:(CFAbsoluteTime)maximumBufferAge;

/// Returns a new pixel buffer instance either by recycling an already allocated and unused buffer
/// in the pool, or if there are not buffers available, by enlarging the pool and allocating a new
/// buffer.
///
/// Raises if a pixel buffer cannot be returned, which is most likely caused by allocation failures.
///
/// @note instances of the returned \c CVPixelBufferRef objects are never reused, and the returned
/// value is always a new instance. It is the underlying pixel buffer that might be reused.
- (lt::Ref<CVPixelBufferRef>)createPixelBuffer;

/// Returns a new pixel buffer instance either by recycling an already allocated and unused buffer
/// in the pool or by attempting to allocate a new buffer.
///
/// Returns \c nullptr reference if the maximum allocated buffer count, as given by \c count, would
/// have been exceeded as the result of this call.
///
/// Raises if a buffer cannot be returned, due to any other reason.
///
/// @note instances of the returned \c CVPixelBufferRef objects are never reused, and the returned
/// value is always a new instance. It is the underlying pixel buffer that might be reused.
- (lt::Ref<CVPixelBufferRef>)createPixelBufferNotExceedingMaximumBufferCount:(size_t)count;

/// Flushes the pool, by deallocating all unused pixel buffers, regardless of their age.
- (void)flush;

/// Flushes the pool, by deallocating only unused pixel buffer that have reached the maximum age
/// (as defined by \c maximumBufferAge parameter). If aging is disabled, the result is similar to
/// \c flush.
- (void)flushAged;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Pixel format of the pixel buffers in the pool.
@property (readonly, nonatomic) OSType pixelFormat;

/// Width in pixels of each pixel buffer in the pool.
@property (readonly, nonatomic) size_t width;

/// Height in pixels of each pixel buffer in the pool.
@property (readonly, nonatomic) size_t height;

@end

NS_ASSUME_NONNULL_END
