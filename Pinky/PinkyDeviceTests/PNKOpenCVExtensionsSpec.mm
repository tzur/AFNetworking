// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKOpenCVExtensions.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>

SpecBegin(PNKOpenCVExtensions)

/// Red color used for creating multi channel test image.
const static cv::Vec4b kRedColor(255, 0, 0, 255);

/// Multi channel test image image width.
static const NSUInteger kMultiChannelWidth = 4;

/// Multi channel test image height.
static const NSUInteger kMultiChannelHeight = 4;

context(@"creating Mat from MTLTexture", ^{
  __block id<MTLDevice> device;
  __block MTKTextureLoader *textureLoader;
  __block id<MTLTexture> singleChannelTexture;
  __block id<MTLTexture> multiChannelTexture;
  __block cv::Mat1b singleChannelMat;
  __block cv::Mat4b multiChannelMat;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
    textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];

    NSError *error;
    multiChannelMat = cv::Mat4b(kMultiChannelWidth, kMultiChannelHeight, kRedColor);
    auto multiChannelImage = [[LTImage alloc] initWithMat:multiChannelMat copy:NO];
    multiChannelTexture = [textureLoader newTextureWithCGImage:multiChannelImage.UIImage.CGImage
                                                       options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);

    singleChannelMat = cv::Mat1b(kMultiChannelWidth, kMultiChannelHeight, 1);
    auto singleChannelImage = [[LTImage alloc] initWithMat:singleChannelMat copy:NO];
    singleChannelTexture = [textureLoader newTextureWithCGImage:singleChannelImage.UIImage.CGImage
                                                        options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);
  });

  it(@"should raise an exception when pixel format is not supported", ^{
    expect(^{
      PNKMatFromMTLTexture(singleChannelTexture);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should write texture content correctly", ^{
    auto output = PNKMatFromMTLTexture(multiChannelTexture);
    expect($(output)).to.equalMat($(multiChannelMat));
  });

  it(@"should deep copy texture content", ^{
    auto output = PNKMatFromMTLTexture(multiChannelTexture);
    auto targetSize = CGSizeMake(multiChannelTexture.width, multiChannelTexture.height);
    cv::Mat4b inputData(targetSize.height, targetSize.width);
    PNKCopyMatToMTLTexture(multiChannelTexture, inputData);
    expect($(output)).to.equalMat($(multiChannelMat));
  });
});

context(@"copying Mat to MTLTexture", ^{
  __block id<MTLDevice> device;
  __block MTKTextureLoader *textureLoader;
  __block id<MTLTexture> singleChannelTexture;
  __block id<MTLTexture> multiChannelTexture;
  __block cv::Mat1b singleChannelMat;
  __block cv::Mat4b multiChannelMat;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
    textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];

    NSError *error;
    multiChannelMat = cv::Mat4b(kMultiChannelWidth, kMultiChannelHeight, kRedColor);
    auto multiChannelImage = [[LTImage alloc] initWithMat:multiChannelMat copy:NO];
    multiChannelTexture = [textureLoader newTextureWithCGImage:multiChannelImage.UIImage.CGImage
                                                       options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);

    singleChannelMat = cv::Mat1b(kMultiChannelWidth, kMultiChannelHeight, 1);
    auto singleChannelImage = [[LTImage alloc] initWithMat:singleChannelMat copy:NO];
    singleChannelTexture = [textureLoader newTextureWithCGImage:singleChannelImage.UIImage.CGImage
                                                        options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);
  });

  it(@"should raise an exception when pixel format is not supported", ^{
    auto targetSize = CGSizeMake(singleChannelTexture.width, singleChannelTexture.height);
    cv::Mat1b inputData(targetSize.height, targetSize.width);
    auto region =  MTLRegionMake2D(0, 0, singleChannelTexture.width, singleChannelTexture.height);
    expect(^{
      PNKCopyMatToMTLTextureRegion(singleChannelTexture, region, inputData);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input width doesn't match region width", ^{
    auto targetSize = CGSizeMake(multiChannelTexture.width, multiChannelTexture.height);
    cv::Mat4b inputData(targetSize.height, targetSize.width);
    auto region = MTLRegionMake2D(0, 0, multiChannelTexture.width / 2, multiChannelTexture.height);
    expect(^{
      PNKCopyMatToMTLTextureRegion(multiChannelTexture, region, inputData);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height doesn't match region height", ^{
    auto targetSize = CGSizeMake(multiChannelTexture.width, multiChannelTexture.height);
    cv::Mat4b inputData(targetSize.height, targetSize.width);
    auto region = MTLRegionMake2D(0, 0, multiChannelTexture.width, multiChannelTexture.height / 2);
    expect(^{
      PNKCopyMatToMTLTextureRegion(multiChannelTexture, region, inputData);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input type is not supported", ^{
    auto targetSize = CGSizeMake(multiChannelTexture.width, multiChannelTexture.height);
    cv::Mat1b inputData(targetSize.height, targetSize.width);
    auto region = MTLRegionMake2D(0, 0, multiChannelTexture.width, multiChannelTexture.height);
    expect(^{
      PNKCopyMatToMTLTextureRegion(multiChannelTexture, region, inputData);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should write to texture correctly", ^{
    auto targetSize = CGSizeMake(multiChannelTexture.width, multiChannelTexture.height);
    cv::Mat4b inputData(targetSize.height, targetSize.width);
    PNKCopyMatToMTLTexture(multiChannelTexture, inputData);
    auto outputData = PNKMatFromMTLTexture(multiChannelTexture);
    expect($(outputData)).to.equalMat($(inputData));
  });

  it(@"should write to texture at region correctly", ^{
    cv::Mat4b inputData(1, 1);
    inputData.at<cv::Vec4b>(0, 0) = cv::Vec4b(1, 1, 1, 1);
    PNKCopyMatToMTLTextureRegion(multiChannelTexture, MTLRegionMake2D(0, 0, 1, 1), inputData);
    auto outputData = PNKMatFromMTLTexture(multiChannelTexture);
    multiChannelMat(0, 0) = cv::Vec4b(1, 1, 1, 1);
    expect($(outputData)).to.equalMat($(multiChannelMat));
  });
});

SpecEnd
