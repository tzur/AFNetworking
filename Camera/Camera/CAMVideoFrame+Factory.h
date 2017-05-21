// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <LTEngine/LTRef+LTEngine.h>

#import "CAMVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

/// Category which adds a factory on top of \c CAMVideoFrame's class.
@interface CAMVideoFrame (Factory)

/// Wraps the given \c pixelBuffer with a \c CMSampleBuffer and sets non-image data to be the same
/// as those in \c otherFrame. The created \c CMSampleBuffer becomes the underlying data structure
/// for the created \c CAMVideoFrame.
///
/// @important Ownership of \c pixelBuffer is transferred to the returned \c CAMVideoFrame. Use
/// \c std::move at the call site to acknowledge that, and don't use \c pixelBuffer directly after
/// calling this method.
///
/// @note Throws an exception if any of the buffers or \c CMVideoFormatDescriptionRef cannot be
/// created.
+ (instancetype)videoFrameWithPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer
                  withPropertiesFromFrame:(CAMVideoFrame *)otherFrame;

/// Wraps the given \c pixelBuffer with a \c CMSampleBuffer and sets timing data and metadata as
/// in \c timingInfo and \c propagatableMetadata. The created \c CMSampleBuffer becomes the
/// underlying data structure for the created \c CAMVideoFrame.
///
/// @important Ownership of \c pixelBuffer is transferred to the returned \c CAMVideoFrame. Use
/// \c std::move at the call site to acknowledge that, and don't use \c pixelBuffer directly after
/// calling this method.
///
/// @note Throws an exception if any of the buffers or \c CMVideoFormatDescriptionRef cannot be
/// created.
+ (instancetype)videoFrameWithPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer
                           withTimingInfo:(CMSampleTimingInfo)timingInfo
                 withPropagatableMetadata:(nullable NSDictionary *)propagatableMetadata;

/// Creates a new \c CAMVideoFrame as a deep copy of \c sourceFrame.
+ (instancetype)videoFrameWithVideoFrame:(CAMVideoFrame *)sourceFrame;

@end

NS_ASSUME_NONNULL_END
