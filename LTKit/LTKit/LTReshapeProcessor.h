// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotBaseImageProcessor.h"

@class LTTexture;

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

/// Processor for reshaping a texture placed on a grid mesh. The processor provides an interface for
/// applying common reshape operations on the mesh, performed on GPU. Additionally, by accessing and
/// updating its \c meshDisplacementTexture any custom displacement map can be set.
@interface LTReshapeProcessor : LTOneShotBaseImageProcessor

/// Initializes the processor with with a given \c input texture and \c output texture, and without
/// a freeze mask support.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Initializes the processor with a passthrough fragment shader, the given \c input texture,
/// \c mask which indicates areas to freeze while adjusting the mesh texture, and an \c output
/// texture to write the results into.
- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output;

/// Designated initializer: initializes the processor with the given fragment shader, \c input
/// texture, \c mask which indicates areas to freeze while adjusting the mesh texture, and an
/// \c output texture to write the results into.
- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                                  mask:(LTTexture *)mask output:(LTTexture *)output;

/// Resets the mesh to its original state (no displacement).
- (void)resetMesh;

/// Reshape the current mesh at the given center in the given direction according to the given brush
/// parameters, with respect to the current mask.
///
/// @note \c center and \c direction are given in normalized texture coordinates ([0,1]x[0,1]).
- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(LTReshapeBrushParams)params;

/// Resizes the current mesh at the given center with the given scale according to the given brush
/// parameters, with respect to the current mask.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(LTReshapeBrushParams)params;

/// Unwarps the current mesh at the given center (towards its default state) according to the given
/// brush parameters. The mask (if set) is ignored.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)unwarpWithCenter:(CGPoint)center brushParams:(LTReshapeBrushParams)params;

/// Mesh displacement texture used to alter the mesh vertices. The warp applied to the mesh is
/// according to the content of this texture, as offsets (in normalized texture coordinates) of the
/// mesh vertices covering the texture.
///
/// @see \c LTMeshDrawer.
@property (readonly, nonatomic) LTTexture *meshDisplacementTexture;

@end
