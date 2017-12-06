// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMTestUtils.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

lt::Ref<CMSampleBufferRef> CAMCreateEmptyAudioSampleBuffer(CMSampleTimingInfo timingInfo) {
  CMSampleBufferRef sampleBuffer = NULL;
  OSStatus status = -1;

  AudioStreamBasicDescription audioFormat;
  audioFormat.mSampleRate = 44100.00;
  audioFormat.mFormatID = kAudioFormatLinearPCM;
  audioFormat.mFormatFlags = 0xc;
  audioFormat.mBytesPerPacket= 2;
  audioFormat.mFramesPerPacket= 1;
  audioFormat.mBytesPerFrame = 2;
  audioFormat.mChannelsPerFrame= 1;
  audioFormat.mBitsPerChannel= 16;
  audioFormat.mReserved= 0;

  CMFormatDescriptionRef format = NULL;
  status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioFormat, 0, nil, 0, nil, nil,
                                          &format);
  lt::Ref<CMFormatDescriptionRef> formatRef = lt::makeRef(format);

  if (status != noErr) {
    return lt::Ref<CMSampleBufferRef>();
  }

  status = CMSampleBufferCreate(kCFAllocatorDefault, nil , NO, nil, nil, formatRef.get(), 1, 1,
                                &timingInfo, 0, nil, &sampleBuffer);
  if (status != noErr) {
    return lt::Ref<CMSampleBufferRef>();
  }

  return lt::makeRef(sampleBuffer);
}

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

lt::Ref<CMSampleBufferRef> CAMCreateImageSampleBuffer(CAMPixelFormat *format, CGSize size) {
  lt::Ref<CVImageBufferRef> imageBufferRef =
      LTCVPixelBufferCreate((size_t)size.width, (size_t)size.height, format.cvPixelFormat);

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

lt::Ref<CMSampleBufferRef> CAMCreateBGRASampleBufferForImage(const cv::Mat4b &image) {
  CMSampleTimingInfo sampleTiming = {kCMTimeZero, kCMTimeZero, kCMTimeZero};
  return CAMCreateBGRASampleBufferForImage(image, sampleTiming);
}

lt::Ref<CMSampleBufferRef>
CAMCreateBGRASampleBufferForImage(const cv::Mat4b &image, const CMSampleTimingInfo &sampleTiming) {
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

lt::Ref<CMSampleBufferRef> CAMCreateYCbCr420SampleBufferForImage(const cv::Mat1b &yImage,
                                                                 const cv::Mat2b &cbCrImage) {
  CMSampleTimingInfo sampleTiming = {kCMTimeZero, kCMTimeZero, kCMTimeZero};
  return CAMCreateYCbCr420SampleBufferForImage(yImage, cbCrImage, sampleTiming);
}

lt::Ref<CMSampleBufferRef>
CAMCreateYCbCr420SampleBufferForImage(const cv::Mat1b &yImage, const cv::Mat2b &cbCrImage,
                                      const CMSampleTimingInfo &sampleTiming) {
  LTParameterAssert(cbCrImage.rows == std::ceil(yImage.rows / 2), @"The number of rows in the CbCr "
                    "channel should be exactly half those in the Y channel. Expected:%d, got:%d.",
                    (int)std::ceil(yImage.rows / 2), cbCrImage.rows);
  LTParameterAssert(cbCrImage.cols == std::ceil(yImage.cols / 2), @"The number of cols in the CbCr "
                    "channel should be exactly half those in the Y channel. Expected:%d, got:%d.",
                    (int)std::ceil(yImage.cols / 2), cbCrImage.cols);

  __block lt::Ref<CVImageBufferRef> imageBufferRef =
      LTCVPixelBufferCreate(yImage.cols, yImage.rows,
                            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

  LTCVPixelBufferPlaneImageForWriting(imageBufferRef.get(), 0, ^(cv::Mat *mapped) {
    yImage.copyTo(*mapped);
  });
  LTCVPixelBufferPlaneImageForWriting(imageBufferRef.get(), 1, ^(cv::Mat *mapped) {
    cbCrImage.copyTo(*mapped);
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
