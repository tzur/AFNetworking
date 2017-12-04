// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kupchick.

NS_ASSUME_NONNULL_BEGIN

/// Container protocol that holds an audio frame along with related metadata.
@protocol CAMAudioFrame <NSObject>

/// Returns a \c CMSampleBuffer pointing to the image data of this audio frame.
- (lt::Ref<CMSampleBufferRef>)sampleBuffer;

/// Returns timing info for the audio frame.
- (CMSampleTimingInfo)timingInfo;

@end

/// Concrete implementation of \c id<CAMAudioFrame> backed by a \c CMSampleBuffer.
@interface CAMAudioFrame : NSObject <CAMAudioFrame>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c CMSampleBuffer. \c sampleBuffer must contain an audio buffer.
///
/// @note \c sampleBuffer is retained by this audio frame.
- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
