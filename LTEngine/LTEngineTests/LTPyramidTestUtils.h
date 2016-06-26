// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Creates a gaussian pyramid of the given \c input using the classic hat kernel.
std::vector<cv::Mat1f> LTGaussianPyramidOpenCV(cv::Mat1f const &input);

/// Creates a laplacian pyramid of the given \c input using the classic hat kernel for both
/// downsampling and upsampling.
std::vector<cv::Mat1f> LTLaplacianPyramidOpenCV(cv::Mat1f const &input);

/// Upsample each level in \c imagePyramid and store it in \c imagePyramid itself.
void LTGaussianUpsamplePyramidOpenCV(std::vector<cv::Mat1f> &imagePyramid);

NS_ASSUME_NONNULL_END
