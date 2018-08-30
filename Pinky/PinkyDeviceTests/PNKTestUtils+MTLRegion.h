// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Makes \c MTLRegion from 3 coordinates of origin and 3 components of size.
MTL_INLINE MTLRegion MTLRegionMake(NSUInteger x, NSUInteger y, NSUInteger z, NSUInteger width,
                                   NSUInteger height, NSUInteger depth) {
  return MTLRegionMake3D(x, y, z, width, height, depth);
}

/// Makes \c MTLRegion from origin structure and 3 components of size.
MTL_INLINE MTLRegion MTLRegionMake(MTLOrigin origin, NSUInteger width, NSUInteger height,
                                   NSUInteger depth) {
  return MTLRegionMake(origin.x, origin.y, origin.z, width, height, depth);
}

/// Makes \c MTLRegion from 3 coordinates of origin and size structure.
MTL_INLINE MTLRegion MTLRegionMake(NSUInteger x, NSUInteger y, NSUInteger z, MTLSize size)  {
  return MTLRegionMake(x, y, z, size.width, size.height, size.depth);
}

/// Makes \c MTLRegion from origin and size structures.
MTL_INLINE MTLRegion MTLRegionMake(MTLOrigin origin, MTLSize size) {
  return MTLRegionMake(origin.x, origin.y, origin.z, size.width, size.height, size.depth);
}

NS_ASSUME_NONNULL_END
