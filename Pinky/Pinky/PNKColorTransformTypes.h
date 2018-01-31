// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

namespace pnk {

  /// Color transform to be applied on image.
  enum ColorTransformType : unsigned short {
    /// No transform.
    ColorTransformTypeNone,
    /// Duplicate 1 input channel (Y) into 3 output channels (RGB). If alpha channel presents - set
    /// it to 1.
    ColorTransformTypeYToRGBA
  };

} // namespace pnk
