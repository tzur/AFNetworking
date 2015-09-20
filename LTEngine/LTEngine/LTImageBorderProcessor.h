// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Available symmetrization strategies. Each strategy consists of flipping the texture around 0,
/// 1 (x = 0.5 or y = 0.5) or 2 axis (x = 0.5 and y = 0.5). Flipped values are blended with the
/// original pixels in such a manner that the pixels further away from the seam retain more of their
/// original value.
typedef NS_ENUM(NSUInteger, LTSymmetrizationType) {
  LTSymmetrizationTypeOriginal = 0,
  LTSymmetrizationTypeTop = 1,
  LTSymmetrizationTypeBottom = 2,
  LTSymmetrizationTypeLeft = 3,
  LTSymmetrizationTypeRight = 4,
  LTSymmetrizationTypeTopLeft = 5,
  LTSymmetrizationTypeTopRight = 6,
  LTSymmetrizationTypeBottomLeft = 7,
  LTSymmetrizationTypeBottomRight = 8,
};

/// Add border to the image. Border is constructed out of two frame textures: front and back, which
/// are blended with the image using overlay blending. Front texture is laid on top of the back
/// texture and it is possible to move these two elements one with respect to another, control color
/// and opacity. Mapping of each frame to the input image is done using central cut algorithm and
/// seam on the cut is mitigated using one of the symmetrization strategies.
@interface LTImageBorderProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture, which will have a border added to it and the
/// output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Width of the frame. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat width;
LTPropertyDeclare(CGFloat, width, Width);

/// Spread of the frame. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat spread;
LTPropertyDeclare(CGFloat, spread, Spread);

/// Color that is used to tint the front element, using multiplication blending. Components should
/// be in [0, 1] range. Default color is white (1, 1, 1).
@property (nonatomic) LTVector3 color;
LTPropertyDeclare(LTVector3, color, Color);

/// Opacity of the border. Should be in [0, 1] range. Default value is 1, corresponding to maximum
/// visibility of the border.
@property (nonatomic) CGFloat opacity;
LTPropertyDeclare(CGFloat, opacity, Opacity);

/// Texture of the front element. Passing \c nil will create a grey texture, which is a neutral
/// color in overlay mode.
@property (strong, nonatomic) LTTexture *frontTexture;

/// Texture of the back element. Passing \c nil will create a grey texture, which is a neutral
/// color in overlay mode.
@property (strong, nonatomic) LTTexture *backTexture;

/// Symmetrization strategy for the front texture. Default value is \c LTSymmetrizationTypeOriginal.
@property (nonatomic) LTSymmetrizationType frontSymmetrization;

/// Symmetrization strategy for the back border. Default value is \c LTSymmetrizationTypeOriginal.
@property (nonatomic) LTSymmetrizationType backSymmetrization;

/// The following parameters control the symmetrization distance mask. Mask is built by measuring
/// the minimum distance from the seam and using this distance as an input to the smoothstep
/// function. The following two parameters are the edges of the smoothstep.

/// First edge of symmetrization smoothstep. Should be in [0, 0.5] range. Default value is 0.0.
@property (nonatomic) CGFloat edge0;
LTPropertyDeclare(CGFloat, edge0, Edge0);

/// Second edge of symmetrization smoothstep. Should be in [0, 0.5] range. Default value is 0.25.
@property (nonatomic) CGFloat edge1;
LTPropertyDeclare(CGFloat, edge1, Edge1);

/// Set to \c YES to flip the front texture horizontally. Default value is \c NO.
@property (nonatomic) BOOL frontFlipHorizontal;

/// Set to \c YES to flip the front texture vertically. Default value is \c NO.
@property (nonatomic) BOOL frontFlipVertical;

/// Set to \c YES to flip the back texture horizontally. Default value is \c NO.
@property (nonatomic) BOOL backFlipHorizontal;

/// Set to \c YES to flip the back texture vertically. Default value is \c NO.
@property (nonatomic) BOOL backFlipVertical;

@end
