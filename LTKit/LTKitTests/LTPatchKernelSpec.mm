// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchKernel.h"

SpecBegin(LTPatchKernel)

it(@"should return correct kernel", ^{
  cv::Mat1f kernel = LTPatchKernelCreate(cv::Size(3, 3));

  float corner = 1 / std::powf(M_SQRT2 + 0.1, 2.5);
  float side = 1 / std::powf(1 + 0.1, 2.5);
  float center = 1 / std::powf(0.1, 2.5);

  cv::Mat1f expectedKernel = (cv::Mat1f(3, 3) << corner, side, corner,
                                                 side, center, side,
                                                 corner, side, corner);

  expect($(kernel)).to.equalMat($(expectedKernel));
});

SpecEnd
