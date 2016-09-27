// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMTestUtils.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>

NS_ASSUME_NONNULL_BEGIN

lt::Ref<CMSampleBufferRef> CAMCreateEmptySampleBuffer() {
  CMSampleBufferRef sampleBuffer;
  OSStatus status = CMSampleBufferCreateReady(kCFAllocatorDefault, NULL, NULL, 0, 0, NULL, 0, NULL,
                                              &sampleBuffer);
  LTAssert(((int)status) == 0, @"CMSampleBufferCreate failed, got %d", (int)status);
  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

static lt::Ref<CMVideoFormatDescriptionRef>
CAMCreateVideoFormatDescription(CVImageBufferRef imageBuffer) {
  CMVideoFormatDescriptionRef videoFormat;
  CVReturn videoFormatCreate =
      CMVideoFormatDescriptionCreateForImageBuffer(NULL, imageBuffer, &videoFormat);
  LTAssert(videoFormatCreate == kCVReturnSuccess,
           @"CMVideoFormatDescriptionCreateForImageBuffer failed, got: %d", videoFormatCreate);

  return lt::Ref<CMVideoFormatDescriptionRef>(videoFormat);
}

lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CGSize size) {
  lt::Ref<CVImageBufferRef> imageBufferRef =
      LTCVPixelBufferCreate((size_t)size.width, (size_t)size.height, kCVPixelFormatType_32BGRA);

  lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef =
      CAMCreateVideoFormatDescription(imageBufferRef.get());

  CMSampleTimingInfo sampleTimingInfo = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};

  CMSampleBufferRef sampleBuffer;
  OSStatus sampleBufferCreate =
      CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBufferRef.get(),
                                               videoFormatRef.get(), &sampleTimingInfo,
                                               &sampleBuffer);
  LTAssert(((int)sampleBufferCreate) == 0, @"CMSampleBufferCreateForImageBuffer failed, got: %d",
           (int)sampleBufferCreate);

  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image) {
  CMSampleTimingInfo sampleTiming = {kCMTimeZero, kCMTimeZero, kCMTimeZero};
  return CAMCreateSampleBufferForImage(image, sampleTiming);
}

lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image,
                                                         const CMSampleTimingInfo &sampleTiming) {
  __block lt::Ref<CVImageBufferRef> imageBufferRef =
      LTCVPixelBufferCreate(image.cols, image.rows, kCVPixelFormatType_32BGRA);

  LTCVPixelBufferImageForWriting(imageBufferRef.get(), ^(cv::Mat *mapped) {
    image.copyTo(*mapped);
  });

  lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef =
      CAMCreateVideoFormatDescription(imageBufferRef.get());

  CMSampleBufferRef sampleBuffer;
  OSStatus sampleBufferCreate =
      CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBufferRef.get(),
                                               videoFormatRef.get(), &sampleTiming,
                                               &sampleBuffer);
  LTAssert(((int)sampleBufferCreate) == 0, @"CMSampleBufferCreateForImageBuffer failed, got: %d",
           (int)sampleBufferCreate);

  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

NS_ASSUME_NONNULL_END
