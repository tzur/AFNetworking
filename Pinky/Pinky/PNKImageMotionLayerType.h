// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

namespace pnk {

/// Layer type codes. The layers are ordered by their Z-order, from the nearest (water) to the
/// farthest (sky). This Z-order can later be used to determine the visible layer in cases where a
/// pixel belongs to 2 or more layers.
enum ImageMotionLayerType : unsigned char {
  /// No layer.
  ImageMotionLayerTypeNone,
  /// Water.
  ImageMotionLayerTypeWater,
  /// Grass.
  ImageMotionLayerTypeGrass,
  /// Trees.
  ImageMotionLayerTypeTrees,
  /// Layer without motion - buildings, ground etc.
  ImageMotionLayerTypeStatic,
  /// Sky.
  ImageMotionLayerTypeSky,
  /// Enum value upper bound. This value must never be used as a layer type.
  ImageMotionLayerTypeMax
};

} // namespace pnk
