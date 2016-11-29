// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMVideoFrame+Factory.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>
#import <LTEngine/LTTexture.h>

#import "CAMDevicePreset.h"
#import "CAMSampleTimingInfo.h"
#import "CAMTestUtils.h"

SpecBegin(CAMVideoFrame_Factory)

it(@"should initialize with new pixelBuffer and old CAMVideoFrame", ^{
  cv::Mat4b image = cv::Mat(12, 10, CV_8UC4);
  image(cv::Rect(0, 0, 5, 6)) = cv::Scalar(255, 0, 0, 255);
  image(cv::Rect(5, 0, 5, 6)) = cv::Scalar(0, 255, 0, 255);
  image(cv::Rect(0, 6, 5, 6)) = cv::Scalar(0, 0, 255, 255);
  image(cv::Rect(5, 6, 5, 6)) = cv::Scalar(128, 128, 128, 255);

  CMSampleTimingInfo sampleTiming = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};
  lt::Ref<CMSampleBufferRef> sampleBuffer = CAMCreateBGRASampleBufferForImage(image, sampleTiming);
  CAMVideoFrame *oldVideoFrame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];

  cv::Mat4b expectedImage = cv::Mat(8, 12, CV_8UC4);
  expectedImage(cv::Rect(0, 0, 6, 4)) = cv::Scalar(0, 255, 0, 255);
  expectedImage(cv::Rect(6, 0, 6, 4)) = cv::Scalar(0, 0, 255, 255);
  expectedImage(cv::Rect(0, 4, 6, 4)) = cv::Scalar(128, 128, 128, 255);
  expectedImage(cv::Rect(6, 4, 6, 4)) = cv::Scalar(255, 0, 0, 255);

  lt::Ref<CVPixelBufferRef> newPixelBuffer =  LTCVPixelBufferCreate(expectedImage.cols,
                                                                    expectedImage.rows,
                                                                    kCVPixelFormatType_32BGRA);
  LTCVPixelBufferImageForWriting(newPixelBuffer.get(), ^(cv::Mat *mapped) {
    expectedImage.copyTo(*mapped);
  });

  CAMVideoFrame *newVideoFrame = [CAMVideoFrame videoFrameWithPixelBuffer:std::move(newPixelBuffer)
                                                  withPropertiesFromFrame:oldVideoFrame];

  expect(CAMSampleTimingInfoIsEqual([newVideoFrame timingInfo], [oldVideoFrame timingInfo])).to.
      beTruthy();
  expect($([[newVideoFrame textureAtPlaneIndex:0] image])).to.equalMat($(expectedImage));
  expect([newVideoFrame pixelFormat]).to.equal($(CAMPixelFormatBGRA));
});

SpecEnd
