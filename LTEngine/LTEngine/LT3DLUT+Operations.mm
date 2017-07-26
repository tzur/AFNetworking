// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LT3DLUT+Operations.h"

NS_ASSUME_NONNULL_BEGIN

/// This function calculates parameters for linear interpolation in 1-dimensional color space.
///
/// For an arbitrary function defined on a 1-dimensional homogeneous lattice that covers the
/// <tt>[0, 255]</tt> interval we are interseted in detecting the value of this function in any
/// point of that interval. We do this by linear interpolation from the two nodes that are nearest
/// to the point of interest.
///
/// This functions calculates parameters of such interpolation - namely, the index of the first
/// node to be used for the interpolation and the coefficients to ba applied to the values of the
/// function in the first and the second node to produce the interpolated value.
///
/// @param coordinate coordinate of the point of interest on the <tt>[0, 255]</tt> interval.
///
/// @param size count of lattice nodes.
///
/// @return 3-tuple consisting of:
///
/// * \c index index of the first node to be used for interpolation. The second node is
///   <tt>index + 1</tt>.
///
/// * \c coeff0 coefficient to be used with the function value at the first node.
///
/// * \c coeff1 coefficient to be used with the function value at the second node.
static inline std::tuple<int, float, float> LTGetInterpolationParameters(uchar coordinate,
                                                                         int size) {
  int index;

  float relativeCoordinate = coordinate * (size - 1) / 255.0;
  // For \c coordinate values in the range <tt>[0, 254]</tt> we can safely use the integral part of
  // <tt>coordinate * (size - 1) / 255</tt> as the index of the first node as this value is
  // guaranteed to be the <tt>[0, size - 2]</tt> range. However for <tt>coordinate == 255</tt>
  // this formula would give the first node index <tt>size - 1</tt>. This implies the second node
  // index equal to \c size - out of boundaries. This is why we have specific code for
  // <tt>coordinate == 255</tt>.
  if (coordinate == UCHAR_MAX) {
    index = size - 2;
  } else {
    index = relativeCoordinate;
  }

  float coeff1 = relativeCoordinate - index;
  float coeff0 = 1 - coeff1;

  return std::tuple<int, float, float>(index, coeff0, coeff1);
}

@implementation LT3DLUT (Operations)

- (instancetype)composeWith:(LT3DLUT *)other {
  LTParameterAssert(other.latticeSize == self.latticeSize, @"The other LUT must have lattice size "
                    "equal to that of self - got (%d, %d, %d) vs. (%d, %d, %d)",
                    other.latticeSize.rDimensionSize, other.latticeSize.gDimensionSize,
                    other.latticeSize.bDimensionSize, self.latticeSize.rDimensionSize,
                    self.latticeSize.gDimensionSize, self.latticeSize.bDimensionSize);

  static const auto kChannels = 4;
  auto rSize = self.latticeSize.rDimensionSize;
  auto gSize = self.latticeSize.gDimensionSize;
  auto bSize = self.latticeSize.bDimensionSize;
  std::vector<int> dimensions = {bSize, gSize, rSize};
  int pixelCount = std::accumulate(dimensions.begin(), dimensions.end(), 1, std::multiplies<int>());

  const auto firstData = self.mat.data;

  cv::Mat secondMatrixFloat;
  other.mat.convertTo(secondMatrixFloat, CV_32F);

  cv::Mat4b resultMatrix((int)dimensions.size(), dimensions.data());
  auto resultData = resultMatrix.data;

  // Color values are calculated through trilinear interpolation. For each value the interpolation
  // is done from values in the nodes of some basic cube in the lattice. The exact coordinates of
  // the origin of such cube depend on the point of interest. However, the offsets of all other
  // nodes from the cube's origin node are constant, so it is profitable to pre-calculate them. Each
  // node is defined by its relative coordinates in the BGR space; each relative coordinate can be
  // either \c 0 or \c 1. For example, the node \c 001 has <tt>B=0, G=0, R=1</tt> etc. The offsets
  // are for a LUT matrice of dimensions <tt>(bSize, gSize, rSize)</tt> with 4 channels (RGBA).
  auto offset000 = 0;
  auto offset001 = kChannels * 1;
  auto offset010 = kChannels * rSize;
  auto offset011 = offset010 + offset001;
  auto offset100 = kChannels * rSize * gSize;
  auto offset101 = offset100 + offset001;
  auto offset110 = offset100 + offset010;
  auto offset111 = offset100 + offset010 + offset001;

  // This loop iterates through all pixels of the first LUT (self) and translates them using the
  // second LUT (other). The resulting LUT is the composition of self and other.
  for (int i = 0; i < pixelCount; ++i) {
    int rIndex, gIndex, bIndex;
    float rCoeff0, rCoeff1, gCoeff0, gCoeff1, bCoeff0, bCoeff1;
    std::tie(rIndex, rCoeff0, rCoeff1) = LTGetInterpolationParameters(firstData[kChannels * i],
                                                                      rSize);
    std::tie(gIndex, gCoeff0, gCoeff1) = LTGetInterpolationParameters(firstData[kChannels * i + 1],
                                                                      gSize);
    std::tie(bIndex, bCoeff0, bCoeff1) = LTGetInterpolationParameters(firstData[kChannels * i + 2],
                                                                      bSize);

    for (int channel = 0; channel < kChannels - 1; ++channel) {
      const float *cubeData = &secondMatrixFloat.ptr<float>(bIndex, gIndex, rIndex)[channel];

      // Trilinear interpolation is done here by performing linear interpolaion in R, G and B
      // dimension (in this order).
      float interpolated =
          bCoeff0 * (gCoeff0 * (rCoeff0 * cubeData[offset000] + rCoeff1 * cubeData[offset001]) +
                     gCoeff1 * (rCoeff0 * cubeData[offset010] + rCoeff1 * cubeData[offset011])) +
          bCoeff1 * (gCoeff0 * (rCoeff0 * cubeData[offset100] + rCoeff1 * cubeData[offset101]) +
                     gCoeff1 * (rCoeff0 * cubeData[offset110] + rCoeff1 * cubeData[offset111]));
      resultData[kChannels * i + channel] = (uchar)std::round(interpolated);
    }
    resultData[kChannels * i + 3] = UCHAR_MAX;
  }

  return [[LT3DLUT alloc] initWithLatticeMat:resultMatrix];
}

@end

NS_ASSUME_NONNULL_END
