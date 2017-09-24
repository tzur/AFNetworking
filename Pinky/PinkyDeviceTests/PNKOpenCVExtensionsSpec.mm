// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKOpenCVExtensions.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKOpenCVExtensions)

static const cv::Vec4b kRedColor(255, 0, 0, 255);
static const cv::Vec4b kGreenColor(0, 255, 0, 255);
static const cv::Vec4b kBlueColor(0, 0, 255, 255);

static const NSUInteger kImageWidth = 4;
static const NSUInteger kImageHeight = 4;

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
    multiChannelMat = cv::Mat4b(kImageWidth, kImageHeight, kRedColor);
    auto multiChannelImage = [[LTImage alloc] initWithMat:multiChannelMat copy:NO];
    multiChannelTexture = [textureLoader newTextureWithCGImage:multiChannelImage.UIImage.CGImage
                                                       options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);

    singleChannelMat = cv::Mat1b(kImageWidth, kImageHeight, 1);
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

context(@"creating Mat from MTLTexture of type 2D array", ^{
  __block id<MTLDevice> device;
  __block MPSImage *textureArray;
  __block std::vector<cv::Mat4b> multiChannelMatVector;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
    auto imageDescriptor =
        [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                       width:kImageWidth
                                                      height:kImageHeight
                                             featureChannels:12];
    textureArray = [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kRedColor));
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kGreenColor));
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kBlueColor));
    for (size_t i = 0; i < multiChannelMatVector.size(); ++i) {
      PNKCopyMatToMTLTexture(textureArray.texture, multiChannelMatVector[i], i);
    }
  });

  afterEach(^{
    multiChannelMatVector.clear();
  });

  it(@"should raise when accessing slice out of bounds", ^{
    expect(^{
      auto output = PNKMatFromMTLTexture(textureArray.texture, 3);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should get correct slice", ^{
    for (size_t i = 0; i < multiChannelMatVector.size(); ++i) {
      auto output = PNKMatFromMTLTexture(textureArray.texture, i);
      expect($(output)).to.equalMat($(multiChannelMatVector[i]));
    }
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
    multiChannelMat = cv::Mat4b(kImageWidth, kImageHeight, kRedColor);
    auto multiChannelImage = [[LTImage alloc] initWithMat:multiChannelMat copy:NO];
    multiChannelTexture = [textureLoader newTextureWithCGImage:multiChannelImage.UIImage.CGImage
                                                       options:nil error:&error];
    LTAssert(!error, @"Can't create texture from input image. Error %@", error);

    singleChannelMat = cv::Mat1b(kImageWidth, kImageHeight, 1);
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
    cv::Mat4b inputData(2, 1);
    inputData(0, 0) = cv::Vec4b(1, 1, 1, 1);
    inputData(1, 0) = cv::Vec4b(2, 2, 2, 1);
    PNKCopyMatToMTLTextureRegion(multiChannelTexture, MTLRegionMake2D(0, 0, 1, 2), inputData);
    auto outputData = PNKMatFromMTLTexture(multiChannelTexture);
    multiChannelMat(0, 0) = cv::Vec4b(1, 1, 1, 1);
    multiChannelMat(1, 0) = cv::Vec4b(2, 2, 2, 1);
    expect($(outputData)).to.equalMat($(multiChannelMat));
  });
});

context(@"copying Mat to MTLTexture of type 2D array", ^{
  __block id<MTLDevice> device;
  __block MPSImage *textureArray;
  __block std::vector<cv::Mat4b> multiChannelMatVector;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
    auto imageDescriptor =
    [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                   width:kImageWidth
                                                  height:kImageHeight
                                         featureChannels:12];
    textureArray = [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kRedColor));
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kGreenColor));
    multiChannelMatVector.push_back(cv::Mat4b(kImageWidth, kImageHeight, kBlueColor));
    for (size_t i = 0; i < multiChannelMatVector.size(); ++i) {
      PNKCopyMatToMTLTexture(textureArray.texture, multiChannelMatVector[i], i);
    }
  });

  afterEach(^{
    multiChannelMatVector.clear();
  });

  it(@"should raise when writing to slice out of bounds", ^{
    cv::Mat4b contentMat = cv::Mat4b(kImageWidth, kImageHeight, kRedColor);
    expect(^{
      PNKCopyMatToMTLTexture(textureArray.texture, contentMat, 15);
    }).to.raise(NSInvalidArgumentException);
  });
});

DeviceSpecEnd
