// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTexture+NSURL.h"

#import <LTEngine/LTTexture+Factory.h>
#import <LTKit/LTImageLoader.h>

#import "NSURL+DaVinci.h"

SpecBegin(LTTexture_NSURL)

  static auto const kImageURL = [NSURL URLWithString:@"foo"];

__block LTImageLoader *imageLoaderMock;

beforeEach(^{
  imageLoaderMock = OCMClassMock([LTImageLoader class]);
});

it(@"should return one by one white single-channel byte texture", ^{
  OCMReject([imageLoaderMock imageNamed:OCMOCK_ANY]);

  LTTexture *texture =
      [LTTexture dvn_textureForURL:[NSURL dvn_urlOfOneByOneWhiteSingleChannelByteTexture]
                       imageLoader:imageLoaderMock];

  expect($(texture.image)).to.equalMat($(cv::Mat1b(1, 1, 255)));
});

it(@"should return one by one white RGBA byte texture", ^{
  OCMReject([imageLoaderMock imageNamed:OCMOCK_ANY]);

  LTTexture *texture =
      [LTTexture dvn_textureForURL:[NSURL dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture]
                       imageLoader:imageLoaderMock];

  expect($(texture.image)).to.equalMat($(cv::Mat4b(1, 1, cv::Vec4b(255, 255, 255, 255))));
});

it(@"should return nil for unrecognized image", ^{
  OCMExpect([imageLoaderMock imageNamed:[kImageURL absoluteString]]);

  LTTexture *texture = [LTTexture dvn_textureForURL:kImageURL imageLoader:imageLoaderMock];

  expect(texture).to.beNil();
  OCMVerifyAll(imageLoaderMock);
});

it(@"should return texture for image url", ^{
  UIImage *expectedImage = [UIImage imageNamed:@"DVNBrushTip"
                                      inBundle:[NSBundle bundleForClass:[self class]]
                 compatibleWithTraitCollection:nil];
  OCMStub([imageLoaderMock imageNamed:[kImageURL absoluteString]]).andReturn(expectedImage);

  LTTexture *texture = [LTTexture dvn_textureForURL:kImageURL imageLoader:imageLoaderMock];

  expect($(texture.image)).to.equalMat($([LTTexture textureWithUIImage:expectedImage].image));
});

SpecEnd
