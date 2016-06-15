// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import <LTKit/LTUnorderedMap.h>

#import "LT3DLUT.h"

NS_ASSUME_NONNULL_BEGIN

/// Struct for storing necessary spatial data about an unpacked 3D LUT.
struct LT3DLUTSpatialData {
  /// Lattice size of the unpacked 3D LUT.
  LT3DLUTLatticeSize latticeSize;

  /// Rect describes the area of the 3D LUT upon the image. 3D LUT is represented on the image in
  /// it's \c packedMat form. For that reason, the \c area rect \c size must fit the packed mat size
  /// which derives directly from the \c latticeSize, i.e. the size width must be equal to the \c
  /// latticeSize.rDimensionSize and the the size height must be equal to
  /// <tt>latticeSize.gDimensionSize * latticeSize.bDimensionSize</tt>.
  ///
  /// @see [LT3DLUT packedMat] for more information.
  CGRect area;
};

constexpr bool operator==(const LT3DLUTSpatialData &lhs, const LT3DLUTSpatialData &rhs) {
  return (lhs.latticeSize == rhs.latticeSize) && (lhs.area == rhs.area);
}

constexpr bool operator!=(const LT3DLUTSpatialData &lhs, const LT3DLUTSpatialData &rhs) {
  return !(lhs == rhs);
}

/// Map of unpacked LUTs lattice sizes with identifying string keys.
typedef lt::unordered_map<NSString *, LT3DLUTLatticeSize> LT3DLUTLatticeSizeMap;

/// Map of unpacked LUTs spatial data with identifying string keys.
typedef lt::unordered_map<NSString *, LT3DLUTSpatialData> LT3DLUTSpatialDataMap;

@class LTTextureAtlas;

/// Class for describing a collection of 3D LUTs packed in a single texture, the atlas.
@interface LT3DLUTTextureAtlas : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the class with a given \c atlas and given \c latticeSizes. \c latticeSizes is a
/// dictionary mapping identifying strings to their corresponding unpacked LUT lattice sizes. \c
/// atlas contains in its \c texture the LUT packed mats with their corresponding \c areas.
/// Therefore, the \c atlas.areas and \c latticeSizes maps must strictly fit to each other: both
/// must have an equal keys sets and each area rect size in \c atlas.areas must be equal the LUT
/// packed mat size that derives from its lattice size value in the \c latticeSizes corresponding
/// key.
///
/// @see [LT3DLUT packedMat] for more information.
- (instancetype)initWithTextureAtlas:(LTTextureAtlas *)atlas
                        latticeSizes:(const LT3DLUTLatticeSizeMap &)latticeSizes
    NS_DESIGNATED_INITIALIZER;

/// Packing texture that is composed from a collection of LUT packed mats upon it.
@property (readonly, nonatomic) LTTexture *texture;

/// Dictionary mapping identifying strings to their corresponding unpacked LUT spatial data values.
/// Each spatial data value describes the lattice size of its unpacked LUT and the area of the LUT
/// packed mat upon the \c texture.
@property (readonly, nonatomic) LT3DLUTSpatialDataMap spatialDataMap;

@end

NS_ASSUME_NONNULL_END
