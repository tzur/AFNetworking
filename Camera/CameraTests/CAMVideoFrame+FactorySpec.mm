// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMVideoFrame+Factory.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>
#import <LTEngine/LTTexture.h>

#import "CAMDevicePreset.h"
#import "CAMSampleTimingInfo.h"
#import "CAMTestUtils.h"

SpecBegin(CAMVideoFrame_Factory)

__block cv::Mat4b image;
__block CMSampleTimingInfo sampleTiming;
__block lt::Ref<CMSampleBufferRef> sampleBuffer;
__block CAMVideoFrame *oldVideoFrame;
__block cv::Mat4b expectedImage;
__block lt::Ref<CVPixelBufferRef> newPixelBuffer;

beforeEach(^{
  image = cv::Mat(12, 10, CV_8UC4);
  image(cv::Rect(0, 0, 5, 6)) = cv::Scalar(255, 0, 0, 255);
  image(cv::Rect(5, 0, 5, 6)) = cv::Scalar(0, 255, 0, 255);
  image(cv::Rect(0, 6, 5, 6)) = cv::Scalar(0, 0, 255, 255);
  image(cv::Rect(5, 6, 5, 6)) = cv::Scalar(128, 128, 128, 255);

  sampleTiming = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};
  sampleBuffer = CAMCreateBGRASampleBufferForImage(image, sampleTiming);
  oldVideoFrame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];

  expectedImage = cv::Mat(8, 12, CV_8UC4);
  expectedImage(cv::Rect(0, 0, 6, 4)) = cv::Scalar(0, 255, 0, 255);
  expectedImage(cv::Rect(6, 0, 6, 4)) = cv::Scalar(0, 0, 255, 255);
  expectedImage(cv::Rect(0, 4, 6, 4)) = cv::Scalar(128, 128, 128, 255);
  expectedImage(cv::Rect(6, 4, 6, 4)) = cv::Scalar(255, 0, 0, 255);

  newPixelBuffer = LTCVPixelBufferCreate(expectedImage.cols, expectedImage.rows,
                                         kCVPixelFormatType_32BGRA);
  LTCVPixelBufferImageForWriting(newPixelBuffer.get(), ^(cv::Mat *mapped) {
    expectedImage.copyTo(*mapped);
  });
});

it(@"should initialize with new pixelBuffer and old CAMVideoFrame", ^{
  CAMVideoFrame *newVideoFrame = [CAMVideoFrame videoFrameWithPixelBuffer:std::move(newPixelBuffer)
                                                  withPropertiesFromFrame:oldVideoFrame];

  expect(CAMSampleTimingInfoIsEqual([newVideoFrame timingInfo], [oldVideoFrame timingInfo])).to.
      beTruthy();
  expect($([[newVideoFrame textureAtPlaneIndex:0] image])).to.equalMat($(expectedImage));
  expect([newVideoFrame pixelFormat]).to.equal($(CAMPixelFormatBGRA));
});

it(@"should initialize with new pixelBuffer and metadata of the old CAMVideoFrame", ^{
  CAMVideoFrame *newVideoFrame = [CAMVideoFrame videoFrameWithPixelBuffer:std::move(newPixelBuffer)
                                                           withTimingInfo:sampleTiming
                                                 withPropagatableMetadata:nil];

  expect(CAMSampleTimingInfoIsEqual([newVideoFrame timingInfo], [oldVideoFrame timingInfo])).to.
      beTruthy();
  expect($([[newVideoFrame textureAtPlaneIndex:0] image])).to.equalMat($(expectedImage));
  expect([newVideoFrame pixelFormat]).to.equal($(CAMPixelFormatBGRA));
});

it(@"should create a copy of CAMVideoFrame", ^{
  CAMVideoFrame *newVideoFrame = [CAMVideoFrame videoFrameWithVideoFrame:oldVideoFrame];

  expect(CAMSampleTimingInfoIsEqual([newVideoFrame timingInfo], [oldVideoFrame timingInfo])).to.
      beTruthy();
  expect($([[newVideoFrame textureAtPlaneIndex:0] image])).to.equalMat($(image));
  expect([newVideoFrame pixelFormat]).to.equal($(CAMPixelFormatBGRA));

  expect(oldVideoFrame.pixelBuffer.get()).toNot.equal(newVideoFrame.pixelBuffer.get());
});

SpecEnd
