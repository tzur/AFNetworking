// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "UIImage+Factory.h"

#import "LTImage.h"
#import "LTTexture+Factory.h"

SpecBegin(UIImage)

it(@"should should convert LTTexture into UIImage", ^{
  auto originalMat = cv::Mat4b(2, 1, cv::Vec4b(1, 2, 3, 4));
  auto texture = [LTTexture textureWithImage:originalMat];
  auto uiImage = [UIImage lt_imageWithTexture:texture];
  auto ltImage = [[LTImage alloc] initWithImage:uiImage];
  expect($(ltImage.mat)).to.equalMat($(originalMat));
});

it(@"should should convert cv::Mat into UIImage", ^{
  auto originalMat = cv::Mat4b(2, 1, cv::Vec4b(1, 2, 3, 4));
  auto uiImage = [UIImage lt_imageWithMat:originalMat];
  auto ltImage = [[LTImage alloc] initWithImage:uiImage];
  expect($(ltImage.mat)).to.equalMat($(originalMat));
});

SpecEnd
