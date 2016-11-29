// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTTexture.h>

#import "CAMSampleTimingInfo.h"
#import "CAMTestUtils.h"
#import "CAMDevicePreset.h"

SpecBegin(CAMVideoFrame)

__block cv::Mat image;
__block CMSampleTimingInfo sampleTiming;
__block lt::Ref<CMSampleBufferRef> sampleBuffer;

beforeEach(^{
  image = cv::Mat(12, 10, CV_8UC4);
  image(cv::Rect(0, 0, 5, 6)) = cv::Scalar(255, 0, 0, 255);
  image(cv::Rect(5, 0, 5, 6)) = cv::Scalar(0, 255, 0, 255);
  image(cv::Rect(0, 6, 5, 6)) = cv::Scalar(0, 0, 255, 255);
  image(cv::Rect(5, 6, 5, 6)) = cv::Scalar(128, 128, 128, 255);

  sampleTiming = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};

  sampleBuffer = CAMCreateBGRASampleBufferForImage(image, sampleTiming);
});

context(@"initialization and basic properties", ^{
  __block CAMVideoFrame *frame;

  beforeEach(^{
    frame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];
  });

  it(@"should initialize correctly", ^{
    expect([frame sampleBuffer].get()).to.equal(sampleBuffer.get());
  });

  it(@"should retain sample buffer and release after dealloc", ^{
    lt::Ref<CMSampleBufferRef> localSampleBuffer = CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA),
                                                                              CGSizeMake(3, 6));
    CMSampleBufferRef sampleBufferRef = localSampleBuffer.get();
    NSInteger initialRetainCount = CFGetRetainCount(sampleBufferRef);
    @autoreleasepool {
      CAMVideoFrame * __unused anotherFrame =
          [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBufferRef];
      expect(CFGetRetainCount(sampleBufferRef)).to.beGreaterThan(initialRetainCount);
    }
    expect(CFGetRetainCount(sampleBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should not retain sample buffer after returned lt::Ref is released", ^{
    CMSampleBufferRef sampleBufferRef = sampleBuffer.get();
    NSInteger initialRetainCount = CFGetRetainCount(sampleBufferRef);

    lt::Ref<CMSampleBufferRef> sampleBufferLTRef = [frame sampleBuffer];
    sampleBufferLTRef.reset(nullptr);

    expect(CFGetRetainCount(sampleBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should return original sample buffer's image buffer", ^{
    expect([frame pixelBuffer].get()).to.equal(CMSampleBufferGetImageBuffer(sampleBuffer.get()));
  });

  it(@"should not retain internal pixel buffer after deallocation", ^{
    lt::Ref<CMSampleBufferRef> localSampleBuffer = CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA),
                                                                              CGSizeMake(3, 6));
    CMSampleBufferRef sampleBufferRef = localSampleBuffer.get();
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(localSampleBuffer.get());
    NSInteger initialRetainCount = CFGetRetainCount(pixelBufferRef);
    @autoreleasepool {
      CAMVideoFrame * __unused anotherFrame =
          [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBufferRef];
    }
    expect(CFGetRetainCount(pixelBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should not retain internal pixel buffer after returned lt::Ref is released", ^{
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer.get());
    NSInteger initialRetainCount = CFGetRetainCount(pixelBufferRef);

    lt::Ref<CVPixelBufferRef> pixelBuffer = [frame pixelBuffer];
    pixelBuffer.reset(nullptr);

    expect(CFGetRetainCount(pixelBufferRef)).to.equal(initialRetainCount);
  });

  it(@"should return timing info", ^{
    expect(CAMSampleTimingInfoIsEqual([frame timingInfo], sampleTiming)).to.beTruthy();
  });

  it(@"should return orientation", ^{
    expect([frame exifOrientation]).to.equal(0);

    NSDictionary *attachments = @{@"Orientation": @5};
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)attachments,
                     kCMAttachmentMode_ShouldPropagate);

    expect([frame exifOrientation]).to.equal(5);
  });

  it(@"should return pixel format", ^{
    expect([frame pixelFormat]).to.equal($(CAMPixelFormatBGRA));
  });

  it(@"should return size", ^{
    expect([frame size]).to.equal(CGSizeMake(10, 12));
  });
});

context(@"conversion to UIImage", ^{
  __block CAMVideoFrame *frame;
  __block UIImage *uiImage;

  beforeEach(^{
    frame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];
    uiImage = [frame image];
  });

  it(@"should create image with correct size", ^{
    expect(uiImage.size).to.equal(CGSizeMake(image.cols, image.rows));
    expect(uiImage.scale).to.equal(1);
  });

  it(@"should create image with correct contents converted to RGBA", ^{
    cv::Mat swizzledImage(image.size(), image.type());

    static const int rgbaToBgra[] = {0, 2, 1, 1, 2, 0, 3, 3};
    cv::mixChannels(&image, 1, &swizzledImage, 1, rgbaToBgra, 4);

    expect($([[LTImage alloc] initWithImage:uiImage].mat)).to.equalMat($(swizzledImage));
  });
});

context(@"conversion to LTTexture", ^{
  __block CAMVideoFrame *frame;
  __block LTTexture *texture;

  beforeEach(^{
    frame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];
    texture = [frame textureAtPlaneIndex:0];
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should create texture with correct size", ^{
    expect(texture.size).to.equal(CGSizeMake(image.cols, image.rows));
  });

  it(@"should create texture with correct contents", ^{
    expect($([texture image])).to.equalMat($(image));
  });

  it(@"should raise exception when planeIndex is out of bounds", ^{
    expect(^{
      LTTexture * __unused anotherTexture = [frame textureAtPlaneIndex:1];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"propagatableMetadata", ^{
  __block CAMVideoFrame *frame;

  beforeEach(^{
    frame = [[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer.get()];
  });

  it(@"should return nil if the metatdata empty", ^{
    expect([frame propagatableMetadata]).to.beNil();
  });

  it(@"should return nil if there is no propagatable metatdata", ^{
    NSDictionary *attachments = @{@"Orientation": @5};
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)attachments,
                     kCMAttachmentMode_ShouldNotPropagate);

    expect([frame propagatableMetadata]).to.beNil();
  });

  it(@"should return propagatable metatdata", ^{
    NSDictionary *attachments = @{@"Orientation": @5};
    CMSetAttachments(sampleBuffer.get(), (__bridge CFDictionaryRef)attachments,
                     kCMAttachmentMode_ShouldPropagate);

    expect([frame propagatableMetadata]).to.equal(attachments);
  });
});

SpecEnd
