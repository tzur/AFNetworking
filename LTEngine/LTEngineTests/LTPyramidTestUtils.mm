// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTPyramidTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

template<typename T>
void LTSetMatChannelToValue(cv::Mat &mat, int channelToSet, T value) {
  if (channelToSet >= mat.channels()) {
    return;
  }

  const int cols = mat.cols;
  const int step = mat.channels();
  const int rows = mat.rows;

  for (int currentRow = 0; currentRow < rows; ++currentRow) {
    T *currentRowPointer = mat.ptr<T>(currentRow) + channelToSet;
    T *currentRowEndPointer = currentRowPointer + cols * step;
    for (; currentRowPointer != currentRowEndPointer; currentRowPointer += step) {
      *currentRowPointer = value;
    }
  }
}

std::vector<cv::Mat> LTGaussianPyramidOpenCV(cv::Mat const &input) {
  std::vector<cv::Mat> gaussianPyramid;
  cv::Size size = input.size();
  int maxlevel = static_cast<int>(logf(static_cast<float>(cv::min(size.width, size.height))) /
                                  logf(2.0f));
  cv::buildPyramid(input, gaussianPyramid, maxlevel);
  return gaussianPyramid;
}

std::vector<cv::Mat> LTLaplacianPyramidOpenCV(cv::Mat const &input) {
  std::vector<cv::Mat> imagePyramid = LTGaussianPyramidOpenCV(input);
  for (size_t level = 0; level < imagePyramid.size() - 1; ++level) {
    cv::Mat upSample;
    cv::pyrUp(imagePyramid[level + 1], upSample, imagePyramid[level].size());
    imagePyramid[level] -= upSample;

    // Make sure that alpha channel is always 1 and not 0 due to subtraction.
    if (input.channels() == 4) {
      switch (input.depth()) {
        case CV_8U:
          LTSetMatChannelToValue<unsigned char>(imagePyramid[level], 3, 1);
          break;
        case CV_32F:
          LTSetMatChannelToValue<float>(imagePyramid[level], 3, 1.0f);
          break;
      }
    }
  }
  return imagePyramid;
}

void LTGaussianUpsamplePyramidOpenCV(std::vector<cv::Mat> &imagePyramid) {
  for(size_t lvl = 0; lvl < imagePyramid.size() - 1; ++lvl) {
    cv::Mat up;
    cv::pyrUp(imagePyramid[lvl + 1], up, imagePyramid[lvl].size());
    imagePyramid[lvl] = up;
  }
}

NS_ASSUME_NONNULL_END
