// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTPyramidTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

std::vector<cv::Mat1f> LTGaussianPyramidOpenCV(cv::Mat1f const &input) {
  std::vector<cv::Mat1f> gaussianPyramid;
  cv::Size size = input.size();
  int maxlevel = static_cast<int>(logf(static_cast<float>(cv::min(size.width, size.height))) /
                                  logf(2.0f));
  cv::buildPyramid(input, gaussianPyramid, maxlevel);
  return gaussianPyramid;
}

std::vector<cv::Mat1f> LTLaplacianPyramidOpenCV(cv::Mat1f const &input) {
  std::vector<cv::Mat1f> imagePyramid = LTGaussianPyramidOpenCV(input);
  for (size_t level = 0; level < imagePyramid.size() - 1; ++level) {
    cv::Mat1f upSample;
    cv::pyrUp(imagePyramid[level + 1], upSample, imagePyramid[level].size());
    imagePyramid[level] -= upSample;
  }
  return imagePyramid;
}

void LTGaussianUpsamplePyramidOpenCV(std::vector<cv::Mat1f> &imagePyramid) {
  for(size_t lvl = 0; lvl < imagePyramid.size() - 1; ++lvl) {
    cv::Mat1f up;
    cv::pyrUp(imagePyramid[lvl + 1], up, imagePyramid[lvl].size());
    imagePyramid[lvl] = up;
  }
}

NS_ASSUME_NONNULL_END
