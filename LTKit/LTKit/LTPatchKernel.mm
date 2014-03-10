// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchKernel.h"

cv::Mat1f LTPatchKernelCreate(const cv::Size &size) {
  cv::Mat1f kernel(size);

  cv::Point2f center(size.width / 2, size.height / 2);
  for (int y = 0; y < size.height; ++y) {
    for (int x = 0; x < size.width; ++x) {
      cv::Point2f current(x, y);
      float distanceToCenter = cv::norm(center - current);
      float value = 1.f / std::powf(distanceToCenter + 0.1f, 2.5f);
      kernel(y, x) = value;
    }
  }

  return kernel;
}
