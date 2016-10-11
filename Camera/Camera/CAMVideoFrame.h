// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <CoreMedia/CMSampleBuffer.h>

@class CAMPixelFormat, LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Container protocol that holds a video frame along with related metadata.
@protocol CAMVideoFrame <NSObject>

/// Returns a \c CMSampleBuffer pointing to the image data of this video frame.
- (lt::Ref<CMSampleBufferRef>)sampleBuffer;

/// Returns a \c CVPixelBuffer pointing to the image data of this video frame.
- (lt::Ref<CVPixelBufferRef>)pixelBuffer;

/// Returns a \c UIImage with a copy of the contents of this video frame. The returned image is
/// always RGBA, no matter what \c pixelFormat this video frame has. This is an expensive operation.
- (UIImage *)image;

/// Returns a \c LTTexture with the contexts of this \c CAMVideoFrame. When possible, this is a
/// zero-copy operation, and the returned texture is backed by this video frame's data. Otherwise,
/// the data is copied.
///
/// The returned texture is created on the current thread using the current \c LTGLContext. If
/// there is no current \c LTGLContext or the creation of the texture fails, an exception is raised.
///
/// @param planeIndex Plane index to create a texture from. Raises \c NSInvalidArgumentException if
/// the requested index doesn't exist in the frame, or if the frame is non-planer and \c planeIndex
/// is not \c 0.
///
/// @note You must take extra care when referencing the returned texture. GPU - CPU synchronization
/// falls into your responsibility. See \c LTMMTexture for more info.
- (LTTexture *)textureAtPlaneIndex:(NSUInteger)planeIndex;

/// Timing info for the video frame.
- (CMSampleTimingInfo)timingInfo;

/// Returns propagatable metadata of \c sampleBuffer, or \c nil if the \c sampleBuffer doesn't
/// have metadata.
- (nullable NSDictionary *)propagatableMetadata;

/// Orientation of the video frame, according to EXIF specification.
///
/// @see http://sylvana.net/jpegcrop/exif_orientation.html
/// @see http://www.exif.org/Exif2-2.PDF, page 18
- (int)exifOrientation;

/// Pixel format of the image data of this video frame.
- (CAMPixelFormat *)pixelFormat;

/// Size of the video frame, in pixels.
- (CGSize)size;

@end

/// Concrete implementation of \c id<CAMVideoFrame> backed by a \c CMSampleBuffer.
@interface CAMVideoFrame : NSObject <CAMVideoFrame>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c CMSampleBuffer. \c sampleBuffer must contain an image buffer.
///
/// @note \c sampleBuffer is retained by this video frame.
- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
