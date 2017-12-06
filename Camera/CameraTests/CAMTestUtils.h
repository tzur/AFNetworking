// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CAMPixelFormat;

/// Creates an empty data ready audio \c CMSampleBuffer with the given \c timingInfo.
lt::Ref<CMSampleBufferRef> CAMCreateEmptyAudioSampleBuffer(CMSampleTimingInfo timingInfo);

/// Creates an empty data ready \c CMSampleBuffer.
lt::Ref<CMSampleBufferRef> CAMCreateEmptySampleBuffer();

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the given \c size and
/// \c format.
lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CAMPixelFormat *format, CGSize size);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c image and a default \c sampleTiming. The underlying \c CVImageBuffer has BGRA pixel
/// format.
lt::Ref<CMSampleBufferRef> CAMCreateBGRASampleBufferForImage(const cv::Mat4b &image);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c image and the given \c sampleTiming. The underlying \c CVImageBuffer has BGRA pixel
/// format.
lt::Ref<CMSampleBufferRef>
CAMCreateBGRASampleBufferForImage(const cv::Mat4b &image, const CMSampleTimingInfo &sampleTiming);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c yImage, \c cbCrImage and a default \c sampleTiming. The underlying \c CVImageBuffer has
/// 420YCbCr Full Range pixel format.
///
/// @note \c cbCrImage.size() should be exactly half of \c yImage.size() to comply with the 420
/// subsampling scheme.
lt::Ref<CMSampleBufferRef> CAMCreateYCbCr420SampleBufferForImage(const cv::Mat1b &yImage,
                                                                 const cv::Mat2b &cbCrImage);

/// Creates a ready \c CMSampleBuffer with an underlying \c CVImageBuffer with the content of the
/// given \c yImage, \c cbCrImage and the given \c sampleTiming. The underlying \c CVImageBuffer has
/// 420YCbCr Full Range pixel format.
///
/// @note \c cbCrImage.size() should be exactly half of \c yImage.size() to comply with the 420
/// subsampling scheme.
lt::Ref<CMSampleBufferRef>
CAMCreateYCbCr420SampleBufferForImage(const cv::Mat1b &yImage, const cv::Mat2b &cbCrImage,
                                      const CMSampleTimingInfo &sampleTiming);

NS_ASSUME_NONNULL_END
