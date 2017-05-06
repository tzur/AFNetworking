// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Creates a gaussian pyramid of the given \c input using the classic hat kernel. The pyramid is
/// built using dyadic scaling from level \c i to <tt>i + 1</tt>. Starting from level 1 being the
/// same size as the original \c input.
///
/// @param upToLevel decides the highest level to which the pyramid is built. Default parameter is
/// used to build the pyramid to the highest level of <tt>max(1, floor(log2(min(input.size))))</tt>.
std::vector<cv::Mat> LTGaussianPyramidOpenCV(const cv::Mat &input, int upToLevel = -1);

/// Creates a laplacian pyramid of the given \c input using the classic hat kernel for both
/// downsampling and upsampling. \c upToLevel is used similarly to \c LTGaussianPyramidOpenCV.
std::vector<cv::Mat> LTLaplacianPyramidOpenCV(const cv::Mat &input, int upToLevel = -1);

/// Upsample each level in \c imagePyramid and store it in \c imagePyramid itself.
void LTGaussianUpsamplePyramidOpenCV(std::vector<cv::Mat> &imagePyramid);

/// Blends two images according to their weights using a laplacian pyramid blending. Blending is
/// performed from the finest level (1) and up to \c upToLevel. For each level of the return value
/// the applied operation is <tt>output[i] = LTLaplacianPyramid(input1)[i] *
/// LTGaussianPyramid(weights1)[i] + LTLaplacianPyramid(input2)[i] * LTGaussianPyramid(weights2)[i]
/// </tt>.
std::vector<cv::Mat> LTLaplacianPyramidBlendOpenCV(const cv::Mat &input1,
                                                   const cv::Mat1hf &weights1,
                                                   const cv::Mat &input2,
                                                   const cv::Mat1hf &weights2,
                                                   int upToLevel);

NS_ASSUME_NONNULL_END
