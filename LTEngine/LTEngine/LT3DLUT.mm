// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUT.h"

#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LT3DLUT () {
  /// Matrix representing this 3D lookup table, of type \c CV_8UC4. The dimensions of the matrix are
  /// reversal to the RGB dimensions. That is, given color indices <tt>(r, g, b)</tt>, the matching
  /// element in the matrix is at <tt>mat(b, g, r)</tt>.
  cv::Mat _mat;
}

@end

@implementation LT3DLUT

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithLatticeMat:(const cv::Mat &)lattice {
  LTParameterAssert(lattice.type() == CV_8UC4, @"Lattice must be of type CV_8UC4 (%d). Input type "
                    @"is %d", CV_8UC4, lattice.type());

  if (self = [super init]) {
    [self validateDimensionsOfLattice:lattice];
    _latticeSize = {lattice.size[2], lattice.size[1], lattice.size[0]};
    _mat = lattice.clone();
  }
  
  return self;
}

- (void)validateDimensionsOfLattice:(const cv::Mat &)lattice {
  LTParameterAssert(lattice.dims == 3, @"Lattice must have 3 dimensions but input matrix is "
                    @"%d-dimensional", lattice.dims);

  for (int i = 0; i < 3; ++i) {
    LTParameterAssert(lattice.size[i] >= 2 && lattice.size[i] < 256, @"Latice dimension sizes must "
                      "be greater or equal to 2 and be less than 256. Dimension %d size is %d", i,
                      lattice.size[i]);
  }
}

- (instancetype)initWithPackedMat:(const cv::Mat &)packedMat
                     latticeSize:(LT3DLUTLatticeSize)latticeSize {
  LTParameterAssert(packedMat.dims == 2, @"packed mat must be a 2D matrix but input matrix is "
                    @"%d-dimensional", packedMat.dims);
  LTParameterAssert(packedMat.cols == latticeSize.rDimensionSize &&
                    packedMat.rows == (latticeSize.bDimensionSize * latticeSize.gDimensionSize),
                    @"packedMat size must match the lattice size such that packedMat.cols = "
                    "latticeSize.rDimensionSize and packedMat.rows = latticeSize.gDimensionSize * "
                    @"latticeSize.bDimensionSize. packedMat size is (%d, %d)",
                    packedMat.rows, packedMat.cols);

  int latticeDims[] = {latticeSize.bDimensionSize, latticeSize.gDimensionSize,
      latticeSize.rDimensionSize};
  cv::Mat lattice(3, latticeDims, packedMat.type(), packedMat.data);

  return [self initWithLatticeMat:lattice];
}

#pragma mark -
#pragma mark Factory
#pragma mark -

+ (instancetype)identity {
  cv::Mat lattice = [self identityLatticeWithDimensionSizes:{2, 2, 2}];
  return [[LT3DLUT alloc] initWithLatticeMat:lattice];
}

+ (cv::Mat)identityLatticeWithDimensionSizes:(LT3DLUTLatticeSize)latticeSize {
  LTParameterAssert(latticeSize.rDimensionSize >= 2 && latticeSize.gDimensionSize >= 2 &&
                    latticeSize.bDimensionSize >= 2, @"At least one of the lattice dimensions is "
                    "smaller than 2, got: (%d, %d, %d)", latticeSize.rDimensionSize,
                    latticeSize.gDimensionSize, latticeSize.bDimensionSize);
  int latticeDims[] = {latticeSize.bDimensionSize, latticeSize.gDimensionSize,
      latticeSize.rDimensionSize};
  cv::Mat4b lattice(3, latticeDims);
  int largestValue = 255;
  for (int b = 0; b < latticeSize.bDimensionSize; ++b) {
    for (int g = 0; g < latticeSize.gDimensionSize; ++g) {
      for (int r = 0; r < latticeSize.rDimensionSize; ++r) {
        cv::Vec4b &rgbaColor = lattice(b, g, r);
        rgbaColor[0] = (uchar)(r * largestValue / (latticeSize.rDimensionSize - 1));
        rgbaColor[1] = (uchar)(g * largestValue / (latticeSize.gDimensionSize - 1));
        rgbaColor[2] = (uchar)(b * largestValue / (latticeSize.bDimensionSize - 1));
        rgbaColor[3] = (uchar)largestValue;
      }
    }
  }
  return lattice;
}

+ (instancetype)lutFromPackedMat:(const cv::Mat &)packedMat {
  int lutSize = packedMat.cols;
  return [[LT3DLUT alloc] initWithPackedMat:packedMat latticeSize:{lutSize, lutSize, lutSize}];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[LT3DLUT class]]) {
    return NO;
  }

  LT3DLUT *other = (LT3DLUT *)object;

  if (self.latticeSize != other.latticeSize) {
    return NO;
  }

  if (self.mat.type() != other.mat.type()) {
    return NO;
  }

  return std::equal(self.mat.begin<cv::Vec4b>(), self.mat.end<cv::Vec4b>(),
                    other.mat.begin<cv::Vec4b>());
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (cv::Mat)packedMat {
  cv::Mat packedMat(self.latticeSize.bDimensionSize * self.latticeSize.gDimensionSize,
                    self.latticeSize.rDimensionSize, self.mat.type(), self.mat.data);

  return packedMat.clone();
}

@end

NS_ASSUME_NONNULL_END
