// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingImageResize.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

SpecBegin(PNKInpaintingImageUtils)

using namespace pnk_inpainting;

it(@"should resize image properly", ^{
  NSBundle *bundle = NSBundle.lt_testBundle;
  auto input = LTLoadMatFromBundle(bundle, @"building.png");
  auto output = resizeImage(input, cv::Size(384, 384));

  cv::Mat expectedOutput = LTLoadMatFromBundle(bundle, @"building384.png");
  expect($(output)).to.equalMat($(expectedOutput));
});

it(@"should resize mask properly", ^{
  NSBundle *bundle = NSBundle.lt_testBundle;
  auto input = LTLoadMatFromBundle(bundle, @"buildingMask.png");
  auto output = resizeImage(input, cv::Size(384, 384));

  cv::Mat expectedOutput = LTLoadMatFromBundle(bundle, @"buildingMask384.png");
  expect($(output)).to.equalMat($(expectedOutput));
});

SpecEnd
