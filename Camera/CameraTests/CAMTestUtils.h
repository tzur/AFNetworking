// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Creates an empty data ready \c CMSampleBuffer.
lt::Ref<CMSampleBufferRef> CAMCreateEmptySampleBuffer();

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the given \c size.
lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CGSize size);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c image.
lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image);

NS_ASSUME_NONNULL_END
