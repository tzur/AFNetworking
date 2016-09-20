// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Creates an empty data ready \c CMSampleBuffer.
lt::Ref<CMSampleBufferRef> CAMCreateEmptySampleBuffer();

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the given \c size.
/// The underlying \c CVImageBuffer has BGRA pixel format.
lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CGSize size);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c image and a default \c sampleTiming. The underlying \c CVImageBuffer has BGRA pixel
/// format.
lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c image and a the given \c sampleTiming. The underlying \c CVImageBuffer has BGRA pixel
/// format.
lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image,
                                                         const CMSampleTimingInfo &sampleTiming);

NS_ASSUME_NONNULL_END
