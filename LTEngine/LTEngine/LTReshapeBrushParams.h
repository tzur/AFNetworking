// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

/// Container holding the parameters determining the mesh adjustments of the \c LTReshapeProcessor.
typedef struct {
  /// Diameter, in normalized coordinates (where 1.0 corresponds to the larger texture dimension).
  /// Should be (but not enforced) in range [0,1] for reasonable results.
  CGFloat diameter;
  /// Density controlling the falloff of the effect's intensity as the distance from the center of
  /// the brush grows. Lower values yield a rapid falloff. Should be (but not enforced) in range
  /// [0,1] for reasonable results.
  CGFloat density;
  /// Distance invariant factor adjusting the intensity of the effect. Should be (but not enforced)
  /// in range [0,1] for reasonable results.
  CGFloat pressure;
} LTReshapeBrushParams;
