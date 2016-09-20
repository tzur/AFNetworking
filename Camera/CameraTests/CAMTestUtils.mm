// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

lt::Ref<CMSampleBufferRef> CAMCreateEmptySampleBuffer() {
  CMSampleBufferRef sampleBuffer;
  OSStatus status = CMSampleBufferCreateReady(kCFAllocatorDefault, NULL, NULL, 0, 0, NULL, 0, NULL,
                                              &sampleBuffer);
  LTAssert(status == 0, @"CMSampleBufferCreate failed, got %d", status);
  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

static lt::Ref<CVImageBufferRef> CAMCreatePixelBuffer(size_t width, size_t height,
                                                      OSType pixelFormatType) {
  CVImageBufferRef imageBuffer;
  CVReturn pixelBufferCreate =
      CVPixelBufferCreate(NULL, width, height, pixelFormatType, NULL, &imageBuffer);
  LTAssert(pixelBufferCreate == kCVReturnSuccess, @"CVPixelBufferCreate failed, got: %d",
           pixelBufferCreate);

  return lt::Ref<CVImageBufferRef>(imageBuffer);
}

static lt::Ref<CMVideoFormatDescriptionRef>
CAMCreateVideoFormatDescription(const lt::Ref<CVImageBufferRef> &imageBuffer) {
  CMVideoFormatDescriptionRef videoFormat;
  CVReturn videoFormatCreate =
      CMVideoFormatDescriptionCreateForImageBuffer(NULL, imageBuffer.get(), &videoFormat);
  LTAssert(videoFormatCreate == kCVReturnSuccess,
           @"CMVideoFormatDescriptionCreateForImageBuffer failed, got: %d", videoFormatCreate);

  return lt::Ref<CMVideoFormatDescriptionRef>(videoFormat);
}

lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CGSize size) {
  lt::Ref<CVImageBufferRef> imageBufferRef =
      CAMCreatePixelBuffer((size_t)size.width, (size_t)size.height, kCVPixelFormatType_32BGRA);

  lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef =
      CAMCreateVideoFormatDescription(imageBufferRef);

  CMSampleTimingInfo sampleTimingInfo = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};

  CMSampleBufferRef sampleBuffer;
  OSStatus sampleBufferCreate =
      CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBufferRef.get(),
                                               videoFormatRef.get(), &sampleTimingInfo,
                                               &sampleBuffer);
  LTAssert(sampleBufferCreate == 0, @"CMSampleBufferCreateForImageBuffer failed, got: %d",
           sampleBufferCreate);

  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image) {
  CMSampleTimingInfo sampleTiming = {kCMTimeZero, kCMTimeZero, kCMTimeZero};
  return CAMCreateSampleBufferForImage(image, sampleTiming);
}

lt::Ref<CMSampleBufferRef> CAMCreateSampleBufferForImage(const cv::Mat4b &image,
                                                         const CMSampleTimingInfo &sampleTiming) {
  __block lt::Ref<CVImageBufferRef> imageBufferRef =
      CAMCreatePixelBuffer((size_t)image.cols, (size_t)image.rows, kCVPixelFormatType_32BGRA);

  CVReturn lockResult = CVPixelBufferLockBaseAddress(imageBufferRef.get(), 0);
  if (kCVReturnSuccess != lockResult) {
    [LTGLException raise:kLTCVPixelBufferLockingFailedException
                  format:@"Failed locking base address of pixel buffer with error %d",
     (int)lockResult];
  }

  void *base = CVPixelBufferGetBaseAddress(imageBufferRef.get());
  size_t width = CVPixelBufferGetWidth(imageBufferRef.get());
  size_t height = CVPixelBufferGetHeight(imageBufferRef.get());
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBufferRef.get());

  cv::Mat targetImage((int)height, (int)width, CV_8UC4, base, bytesPerRow);
  image.copyTo(targetImage);
  @onExit {
    CVReturn unlockResult = CVPixelBufferUnlockBaseAddress(imageBufferRef.get(), 0);
    if (kCVReturnSuccess != unlockResult) {
      [LTGLException raise:kLTCVPixelBufferLockingFailedException
                    format:@"Failed unlocking base address of pixel buffer with error %d",
       (int)unlockResult];
    }
  };

  lt::Ref<CMVideoFormatDescriptionRef> videoFormatRef =
      CAMCreateVideoFormatDescription(imageBufferRef);

  CMSampleBufferRef sampleBuffer;
  OSStatus sampleBufferCreate =
      CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBufferRef.get(),
                                               videoFormatRef.get(), &sampleTiming,
                                               &sampleBuffer);
  LTAssert(sampleBufferCreate == 0, @"CMSampleBufferCreateForImageBuffer failed, got: %d",
           sampleBufferCreate);

  return lt::Ref<CMSampleBufferRef>(sampleBuffer);
}

NS_ASSUME_NONNULL_END
