// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "CVPixelBuffer+LTEngine.h"

#import <IOSurface/IOSurfaceObjC.h>

SpecBegin(CVPixelBuffer_LTEngine)

context(@"creation", ^{
  it(@"should create a pixel buffer", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(17, 19, kCVPixelFormatType_32BGRA);
    const CVPixelBufferRef pixelBufferReference = pixelBuffer.get();
    const bool empty = !pixelBuffer;

    expect(empty).to.beFalsy();
    expect(CVPixelBufferIsPlanar(pixelBufferReference)).to.beFalsy();
    expect(CVPixelBufferGetWidth(pixelBufferReference)).to.equal(17);
    expect(CVPixelBufferGetHeight(pixelBufferReference)).to.equal(19);
    expect(CVPixelBufferGetPixelFormatType(pixelBufferReference))
        .to.equal(kCVPixelFormatType_32BGRA);
  });

  it(@"should create a planar pixel buffer", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(18, 22, kCVPixelFormatType_420YpCbCr8Planar);
    const CVPixelBufferRef pixelBufferReference = pixelBuffer.get();
    const bool empty = !pixelBuffer;

    expect(empty).to.beFalsy();
    expect(CVPixelBufferIsPlanar(pixelBufferReference)).to.beTruthy();
    expect(CVPixelBufferGetPlaneCount(pixelBufferReference)).to.equal(3);
    expect(CVPixelBufferGetWidthOfPlane(pixelBufferReference, 0)).to.equal(18);
    expect(CVPixelBufferGetHeightOfPlane(pixelBufferReference, 0)).to.equal(22);
    expect(CVPixelBufferGetPixelFormatType(pixelBufferReference))
        .to.equal(kCVPixelFormatType_420YpCbCr8Planar);
  });

  dit(@"should create pixel buffer with iosurface", ^{
    auto iosurface = [[IOSurface alloc] initWithProperties:@{
      IOSurfacePropertyKeyWidth: @3,
      IOSurfacePropertyKeyHeight: @4,
      IOSurfacePropertyKeyPixelFormat: @(kCVPixelFormatType_32BGRA)
    }];
    auto pixelBuffer = LTCVPixelBufferCreateWithIOSurface((__bridge IOSurfaceRef)iosurface, @{});

    expect(CVPixelBufferGetWidth(pixelBuffer.get())).to.equal(iosurface.width);
    expect(CVPixelBufferGetHeight(pixelBuffer.get())).to.equal(iosurface.height);
    expect(CVPixelBufferGetPixelFormatType(pixelBuffer.get()))
        .to.equal(iosurface.pixelFormat);
  });
});

context(@"access to pixel data", ^{
  __block lt::Ref<CVPixelBufferRef> pixelBuffer;

  beforeEach(^{
    pixelBuffer = LTCVPixelBufferCreate(17, 19, kCVPixelFormatType_32BGRA);
  });

  afterEach(^{
    pixelBuffer = nullptr;
  });

  it(@"should lock base address and execute block", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferLockAndExecute(pixelBuffer.get(), 0, ^{
      executed = YES;
      BOOL baseExists = CVPixelBufferGetBaseAddress(pixelBuffer.get()) != NULL;
      expect(baseExists).to.beTruthy();
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct image", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferImage(pixelBuffer.get(), 0, ^(cv::Mat *image) {
      executed = YES;
      expect(image).toNot.beNull();
      expect(image->cols).to.equal(17);
      expect(image->rows).to.equal(19);
      expect(image->type()).to.equal(CV_8UC4);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct image for reading", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat& image) {
      executed = YES;
      expect(image.cols).to.equal(17);
      expect(image.rows).to.equal(19);
      expect(image.type()).to.equal(CV_8UC4);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct image for writing", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
      executed = YES;
      expect(image).toNot.beNull();
      expect(image->cols).to.equal(17);
      expect(image->rows).to.equal(19);
      expect(image->type()).to.equal(CV_8UC4);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should raise when accessing planar image", ^{
    expect(^{
      LTCVPixelBufferPlaneImage(pixelBuffer.get(), 0, 0, ^(cv::Mat *){});
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"access to planar pixel data", ^{
  __block lt::Ref<CVPixelBufferRef> pixelBuffer;

  beforeEach(^{
    pixelBuffer = LTCVPixelBufferCreate(20, 10, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
  });

  afterEach(^{
    pixelBuffer = nullptr;
  });

  it(@"should lock base address and execute block", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferLockAndExecute(pixelBuffer.get(), 0, ^{
      executed = YES;
      BOOL baseExists = CVPixelBufferGetBaseAddress(pixelBuffer.get()) != NULL;
      BOOL baseOfPlane0Exists = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer.get(), 0) != NULL;
      BOOL baseOfPlane1Exists = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer.get(), 1) != NULL;
      expect(baseExists).to.beTruthy();
      expect(baseOfPlane0Exists).to.beTruthy();
      expect(baseOfPlane1Exists).to.beTruthy();
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct planar image of the 1st plane", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferPlaneImage(pixelBuffer.get(), 0, 0, ^(cv::Mat *image) {
      executed = YES;
      expect(image).toNot.beNull();
      expect(image->cols).to.equal(20);
      expect(image->rows).to.equal(10);
      expect(image->type()).to.equal(CV_8UC1);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct planar image of the 2nd plane", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferPlaneImage(pixelBuffer.get(), 1, 0, ^(cv::Mat *image) {
      executed = YES;
      expect(image).toNot.beNull();
      expect(image->cols).to.equal(10);
      expect(image->rows).to.equal(5);
      expect(image->type()).to.equal(CV_8UC2);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct image of the 1st plane for reading", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferPlaneImageForReading(pixelBuffer.get(), 0, ^(const cv::Mat& image) {
      executed = YES;
      expect(image.cols).to.equal(20);
      expect(image.rows).to.equal(10);
      expect(image.type()).to.equal(CV_8UC1);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should get correct image of the 2nd plane for writing", ^{
    __block BOOL executed = NO;
    LTCVPixelBufferPlaneImageForWriting(pixelBuffer.get(), 1, ^(cv::Mat *image) {
      executed = YES;
      expect(image).toNot.beNull();
      expect(image->cols).to.equal(10);
      expect(image->rows).to.equal(5);
      expect(image->type()).to.equal(CV_8UC2);
    });
    expect(executed).to.beTruthy();
  });

  it(@"should raise when accessing non existing plane", ^{
    const CVPixelBufferRef pixelBufferReference = pixelBuffer.get();
    expect(^{
      LTCVPixelBufferPlaneImage(pixelBufferReference, 50, 0, ^(cv::Mat *){});
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when accessing non planar image", ^{
    const CVPixelBufferRef pixelBufferReference = pixelBuffer.get();
    expect(^{
      LTCVPixelBufferImage(pixelBufferReference, 0, ^(cv::Mat *){});
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"unified access", ^{
  context(@"non planar", ^{
    __block lt::Ref<CVPixelBufferRef> pixelBuffer;

    beforeEach(^{
      pixelBuffer = LTCVPixelBufferCreate(17, 19, kCVPixelFormatType_32BGRA);
    });

    afterEach(^{
      pixelBuffer = nullptr;
    });

    it(@"should pass single matrix with buffers data", ^{
      __block BOOL executed = NO;
      LTCVPixelBufferImages(pixelBuffer.get(), 0, ^(const std::vector<cv::Mat> &images) {
        expect(images.size()).to.equal(1);
        expect(images[0].cols).to.equal(17);
        expect(images[0].rows).to.equal(19);
        expect(images[0].type()).to.equal(CV_8UC4);

        cv::Mat m = images[0];

        char *baseAddress = (char *)CVPixelBufferGetBaseAddress(pixelBuffer.get());
        expect(images[0].data).to.equal(baseAddress);

        executed = YES;
      });
      expect(executed).to.beTruthy();
    });
  });

  context(@"planar", ^{
    __block lt::Ref<CVPixelBufferRef> pixelBuffer;

    beforeEach(^{
      pixelBuffer = LTCVPixelBufferCreate(20, 10, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    });

    afterEach(^{
      pixelBuffer = nullptr;
    });

    it(@"should get correct planar images", ^{
      __block BOOL executed = NO;
      LTCVPixelBufferImages(pixelBuffer.get(), 0, ^(const std::vector<cv::Mat> &images) {
        expect(images.size()).to.equal(2);
        expect(images[0].cols).to.equal(20);
        expect(images[0].rows).to.equal(10);
        expect(images[0].type()).to.equal(CV_8UC1);

        char *baseOfPlane0 = (char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer.get(), 0);
        expect(images[0].data).to.equal(baseOfPlane0);

        expect(images[1].cols).to.equal(10);
        expect(images[1].rows).to.equal(5);
        expect(images[1].type()).to.equal(CV_8UC2);

        char *baseOfPlane1 = (char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer.get(), 1);
        expect(images[1].data).to.equal(baseOfPlane1);

        executed = YES;
      });
      expect(executed).to.beTruthy();
    });
  });
});

SpecEnd
