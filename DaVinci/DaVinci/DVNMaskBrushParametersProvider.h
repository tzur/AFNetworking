// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Modes of the mask brush, as defined by \c DVNMaskBrushParametersProvider.
typedef NS_ENUM(NSUInteger, DVNMaskBrushMode) {
  /// Additive mode in which application of the mask brush increases the values, clamped from above
  /// at \c 255 for 8 bit and \c 65279 for 16 bit textures.
  DVNMaskBrushModeAdd,
  /// Subtractive mode in which application of the mask brush decreases the values, clamped from
  /// below at \c 0.
  DVNMaskBrushModeSubtract
};

/// Representation of the texture channel affected by the mask brush, as defined by
/// \c DVNMaskBrushParametersProvider.
typedef NS_ENUM(NSUInteger, DVNMaskBrushChannel) {
  /// Red channel is affected.
  DVNMaskBrushChannelR,
  /// Green channel is affected.
  DVNMaskBrushChannelG,
  /// Blue channel is affected.
  DVNMaskBrushChannelB,
  /// Alpha channel is affected.
  DVNMaskBrushChannelA
};

@class LTTexture;

/// Protocol to be implemented by objects that provide the parameters of a brush that is used to
/// manipulate the values of a single channel of a given texture. The aforementioned texture is
/// called "mask". Therefore, the aforementioned brush is called "mask brush".The mask can be
/// edge-avoiding. For this reason, a special guide texture, the \c edgeAvoidanceGuideTexture, is
/// provided.
@protocol DVNMaskBrushParametersProvider <NSObject>

/// Uniform distance, in floating-point pixel units of the content coordinate, between the samples
/// of a spline along which the mask brush should be drawn. Is greater than \c 0.
@property (readonly, nonatomic) CGFloat spacing;

/// Hardness of the brush outline. In range <tt>[0, 1]</tt>.
@property (readonly, nonatomic) CGFloat hardness;

/// Diameter, in floating-point pixel units of the content coordinate, of the brush. Is greater than
/// \c 0.
@property (readonly, nonatomic) CGFloat diameter;

/// Edge-avoiding sigma parameter. The higher the value of this parameter, the stronger the
/// edge-avoiding effect will be. In range \c [0, 1].
@property (readonly, nonatomic) CGFloat edgeAvoidance;

/// Rate at which color is applied as the brush paints over an area. In range \c [0, 1].
@property (readonly, nonatomic) CGFloat flow;

/// Mode of the mask brush.
@property (readonly, nonatomic) DVNMaskBrushMode mode;

/// Channel affected by the brush.
@property (readonly, nonatomic) DVNMaskBrushChannel channel;

/// Texture that should be used as the edge avoidance guide.
@property (readonly, nonatomic) LTTexture *edgeAvoidanceGuideTexture;

@end

NS_ASSUME_NONNULL_END
