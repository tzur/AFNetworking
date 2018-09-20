// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

/// Value class that represents a subset of pixels of an image. Such subset is also known as a
/// segment or a superpixel.
class SuperPixel {
public:
  /// Initializes with an array of pixel coordinates in the global coordinate system.
  SuperPixel(const std::vector<cv::Point> &coordinates);

  /// Creates a new superpixel with an alternative \c center and the same \c offsets as for the
  /// current superpixel.
  SuperPixel centeredAt(const cv::Point &center);

  /// Point such that set of the \c offsets applied to it define the set of points associated with
  /// superpixel.
  cv::Point center() const {
    return _center;
  }

  /// Offsets of the pixels in the superpixel from \c center organized in a single-column matrix.
  /// Each row contains in its 2 channels offset of a single pixel.
  const cv::Mat2i &offsets() const {
    return _offsets;
  }

  /// Bounding box of the pixels in the superpixel in the global coordinate system.
  cv::Rect boundingBox() const {
    return _boundingBox;
  }

private:
  /// Initializes with \c center, matrix of \c offsets and \c boundingBox.
  SuperPixel(const cv::Point &center, const cv::Mat2i &offsets, const cv::Rect &boundingBox);

  /// Point such that set of the \c offsets applied to it define the set of points associated with
  /// superpixel.
  cv::Point _center;

  /// Offsets of the pixels in the superpixel from \c center organized in a single-column matrix.
  /// Each row contains in its 2 channels offset of a single pixel.
  cv::Mat2i _offsets;

  /// Bounding box of the pixels in the superpixel in the global coordinate system.
  cv::Rect _boundingBox;
};

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
