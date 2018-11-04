// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

/// Returns the region of interest given the \c mask that designates the hole to be filled by an
/// inpainting algorithm.
MTLRegion regionOfInterestAroundHole(const cv::Mat &mask);

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
