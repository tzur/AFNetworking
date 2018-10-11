// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

/// Transfers high-frequency component from the neighborhood of the hole. On the first stage the
/// hole is divided into superpixels wich represent clusters of pixels that are close in both
/// spatial and color spaces. Then the best match for each segment is found outside the hole, and
/// the high-frequency component is copied from that match into the segment.
///
/// @param input Input high-resolution image.
///
/// @param mask Mask of the hole to be filled. Must have the same resolution as \c input. The hole
/// cannot be too small: after resizing \c mask to the size of \c lowFrequency the bounding box of
/// all non-zero (mask) pixels must have both height and width of at least 5.
///
/// @param lowFrequency low resolution copy of \c input with hole already filled (normally by a CNN
/// pass).
///
/// @param output Matrix to be filled with result of high-frequency transfer. Will have the same
/// size as \c input. Area outside \c mask will be copied from \c input. Area covered by \c mask
/// will contain a combination of low frequency component taken from \c lowFrequency and high
/// frequency component taken from areas of \c input outside \c mask.
void transferHighFrequency(const cv::Mat4b &input, const cv::Mat1b &mask,
                           const cv::Mat4b &lowFrequency, cv::Mat4b *output);

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
