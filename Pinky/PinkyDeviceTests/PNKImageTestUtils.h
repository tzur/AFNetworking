// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Calculates the PSNR between \c first and \c second. Both images should have the same dimensions
/// and number of channels. \c ignoreAlphaChannel should only be \c YES when the number of channels
/// of the images is 4, in which case the 4th channel is not included in the calculation of the
/// PSNR. Float precision images are assumed to have a maximal pixel value of \c 1. To adjust for a
/// different maximal pixel the user should add <tt>10 * log10(maxPixelValue ^ 2)</tt> to the result
/// of this function.
double PNKPsnrScore(const cv::Mat &first, const cv::Mat &second, BOOL ignoreAlphaChannel = YES);

NS_ASSUME_NONNULL_END
