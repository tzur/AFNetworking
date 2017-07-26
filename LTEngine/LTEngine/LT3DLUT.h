// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Struct for describing the 3-dimensional lattice sizes of a 3D LUT.
struct LT3DLUTLatticeSize {
  /// Size of the red channel in the lattice.
  int rDimensionSize;
  /// Size of the green channel in the lattice.
  int gDimensionSize;
  /// Size of the blue channel in the lattice.
  int bDimensionSize;
};

constexpr bool operator==(const LT3DLUTLatticeSize &lhs, const LT3DLUTLatticeSize &rhs) {
  return lhs.rDimensionSize == rhs.rDimensionSize && lhs.gDimensionSize == rhs.gDimensionSize &&
      lhs.bDimensionSize == rhs.bDimensionSize;
}

constexpr bool operator!=(const LT3DLUTLatticeSize &lhs, const LT3DLUTLatticeSize &rhs) {
  return !(lhs == rhs);
}

/// 3D Lookup Table. The table defines a map from one 3D color space to another. The table itself
/// is a 3D lattice matrix of type \c CV_8UC4. Each axis of the lattice represents a single channel
/// of the input color space. Interpolation is used to map input color values that are not lattice
/// points.
@interface LT3DLUT : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the lookup table using a given \c lattice. \c lattice must be a 3D matrix of type
/// \c CV_8UC4. Each matrix dimension must be in <tt>{2, 3, ..., 255}</tt>.
- (instancetype)initWithLatticeMat:(const cv::Mat &)lattice NS_DESIGNATED_INITIALIZER;

/// Creates a new 2x2x2 3D LUT that defines the identity map.
+ (instancetype)identity;

/// Initializes with the given \c packedMat. The given \c packedMat must be a 2D matrix of type
/// \c CV_8UC4 with \c m^2 rows and \c m columns, where \c m must be in <tt>{2, 3, ..., 255}</tt>.
/// The \c packedMat consists of \c m <tt>m * m</tt> submatrices, thereby constituting a 3D LUT in a
/// serialized fashion. The element <tt>(i, j)</tt> of the \c packedMat corresponds to the element
/// <tt>(i / m, i % m, j)</tt> of the corresponding 3D matrix in the BGR coordinates.
+ (instancetype)lutFromPackedMat:(const cv::Mat &)packedMat;

/// Returns a copy of the 3D LUT as a 2D matrix. The matrix has <tt>latticeSize.gDimensionSize
/// * latticeSize.bDimensionSize</tt> rows and \c latticeSize.rDimensionSize columns. It
/// consists of \c latticeSize.bDimensionSize submutrices having \c latticeSize.gDimensionSize rows
/// ansd \c latticeSize.rDimensionSize columns each, thereby constituting a 3D LUT in a serialized
/// fashion. The element <tt>(i, j)</tt> of \c packedMat corresponds to the element
/// <tt>(i / latticeSize.bDimensionSize, i % latticeSize.bDimensionSize, j)</tt> of the
/// corresponding 3D matrix in the BGR coordinates. The returned matrix is guaranteed to be
/// continous.
- (cv::Mat)packedMat;

/// Matrix representing this 3D lookup table, of type \c CV_8UC4. The dimensions of the matrix are
/// reversal to the RGB dimensions. That is, given color indices <tt>(r, g, b)</tt>, the matching
/// element in the matrix is at <tt>mat(b, g, r)</tt>.
@property (readonly, nonatomic) const cv::Mat &mat;

/// Dimension sizes of the 3D lattice matrix \c mat.
@property (readonly, nonatomic) LT3DLUTLatticeSize latticeSize;

@end

NS_ASSUME_NONNULL_END
