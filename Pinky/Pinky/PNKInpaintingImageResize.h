// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

/// Resizes \c mask to \c size and returns the result. Uses nearest-neighbor interpolation.
cv::Mat resizeMask(const cv::Mat &mask, cv::Size size);

/// Resizes \c image to \c size and returns the result. Uses bilinear interpolation. Gaussian blur
/// is applied before resize in case of diminishing or after resize in case of enlarging.
cv::Mat resizeImage(const cv::Mat &image, cv::Size size);

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
