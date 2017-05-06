// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTPyramidTestUtils.h"

#import "LTOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

// Sets the specified \c channelToSet of \c mat to be the constant \c value. An efficient
// implementation using pointer arithmetics.
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

// \c weights is a single channel matrix to be multiplied elementwise with each of the channels of
// the matrix \c mat.
template<typename inputT, typename weightT>
void LTMultiplyMatByWeights(cv::Mat &mat, cv::Mat &weights) {
  LTAssert(mat.rows == weights.rows && mat.cols == weights.cols,
           @"Weights size must be equal to input matrix");
  LTAssert(weights.channels() == 1,
           @"Weights matrix must be single channel");

  const int channels = mat.channels();
  cv::Mat rowMatrix = mat.reshape(0, 1);
  cv::Mat rowWeights = weights.reshape(1, 1);

  inputT* rowMatrixPointer = rowMatrix.ptr<inputT>(0);
  weightT* rowWeightsPointer = rowWeights.ptr<weightT>(0);

  for (int col = 0; col < rowMatrix.cols; ++col) {
    for (int chan = 0; chan < channels ; ++chan) {
      (*rowMatrixPointer)[chan] *= *rowWeightsPointer;
    }

    ++rowMatrixPointer;
    ++rowWeightsPointer;
  }
}

// \c weights is a single channel matrix to be multiplied elementwise with the single channel matrix
// \c mat.
template<>
void LTMultiplyMatByWeights<float, float>(cv::Mat &mat, cv::Mat &weights) {
  LTAssert(mat.rows == weights.rows && mat.cols == weights.cols,
           @"Weights size must be equal to input matrix");
  LTAssert(weights.channels() == 1,
           @"Weights matrix must be single channel");

  mat = mat.mul(weights);
}

std::vector<cv::Mat> LTGaussianPyramidOpenCV(const cv::Mat &input, int upToLevel) {
  cv::Size size = input.size();
  int maxLevel = static_cast<int>(logf(static_cast<float>(cv::min(size.width, size.height))) /
                                  logf(2.0f));
  if (upToLevel == -1) {
    upToLevel = maxLevel;
  }
  LTAssert(upToLevel <= maxLevel,
           @"Pyramid cannot be built to %d level which is higher than %d", upToLevel, maxLevel);

  std::vector<cv::Mat> gaussianPyramid;
  cv::buildPyramid(input, gaussianPyramid, upToLevel - 1, cv::BORDER_REPLICATE);
  return gaussianPyramid;
}

std::vector<cv::Mat> LTLaplacianPyramidOpenCV(const cv::Mat &input, int upToLevel) {
  std::vector<cv::Mat> imagePyramid = LTGaussianPyramidOpenCV(input, upToLevel);
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

std::vector<cv::Mat> LTLaplacianPyramidBlendOpenCV(const cv::Mat &input1,
                                                   const cv::Mat1hf &weights1,
                                                   const cv::Mat &input2,
                                                   const cv::Mat1hf &weights2,
                                                   int upToLevel) {
  LTAssert(input1.channels() == input2.channels(),
           @"Input images must have the same number of channels");

  const int channels = input1.channels();

  cv::Mat input1Float;
  if (input1.depth() == CV_8U) {
    LTConvertMat(input1, &input1Float, CV_MAKETYPE(CV_32F, channels));
  } else {
    input1Float = input1;
  }

  cv::Mat input2Float;
  if (input2.depth() == CV_8U) {
    LTConvertMat(input2, &input2Float, CV_MAKETYPE(CV_32F, channels));
  } else {
    input2Float = input2;
  }

  cv::Mat1f weights1Float;
  LTConvertMat(weights1, &weights1Float, CV_32F);
  cv::Mat1f weights2Float;
  LTConvertMat(weights2, &weights2Float, CV_32F);

  std::vector<cv::Mat> imagePyramid1 = LTLaplacianPyramidOpenCV(input1Float, upToLevel);
  std::vector<cv::Mat> imagePyramid2 = LTLaplacianPyramidOpenCV(input2Float, upToLevel);
  std::vector<cv::Mat> weightsPyramid1 = LTGaussianPyramidOpenCV(weights1Float, upToLevel);
  std::vector<cv::Mat> weightsPyramid2 = LTGaussianPyramidOpenCV(weights2Float, upToLevel);

  std::vector<cv::Mat> resultPyramid;
  for (size_t level = 0; level < imagePyramid1.size(); ++level) {
    switch (channels) {
      case 1:
        LTMultiplyMatByWeights<float, float>(imagePyramid1[level], weightsPyramid1[level]);
        LTMultiplyMatByWeights<float, float>(imagePyramid2[level], weightsPyramid2[level]);
        break;
      case 4:
        LTMultiplyMatByWeights<cv::Vec4f, float>(imagePyramid1[level], weightsPyramid1[level]);
        LTMultiplyMatByWeights<cv::Vec4f, float>(imagePyramid2[level], weightsPyramid2[level]);
        break;
    }

    resultPyramid.push_back(imagePyramid1[level] + imagePyramid2[level]);
  }
  return resultPyramid;
}

NS_ASSUME_NONNULL_END
