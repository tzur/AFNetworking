// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Possible values for the \c sourceType of the \c DVNBrush fragment shader.
LTEnumDeclare(NSUInteger, DVNBrushSourceType,
  /// Value for \c sourceType of the \c DVNBrush fragment shader indicating that the \c vColor
  /// should be used as source color.
  DVNBrushSourceTypeColor,
  /// Value for \c sourceType of the \c DVNBrush fragment shader indicating that the
  /// \c sourceTexture should be used for computing the source color.
  DVNBrushSourceTypeSourceTexture,
  /// Value for \c sourceType of the \c DVNBrush fragment shader indicating that the
  /// \c overlayTexture should be used for computing the source color or mask value.
  DVNBrushSourceTypeOverlayTexture
);

NS_ASSUME_NONNULL_END
