// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTImageProcessor.h"
#import "LTPartialProcessing.h"
#import "LTReshapeBrushParams.h"
#import "LTScreenProcessing.h"

NS_ASSUME_NONNULL_BEGIN

@class LTDisplacementMapDrawer, LTMeshProcessor, LTTexture;

/// Processor for reshaping a texture placed on a grid mesh. The processor provides an interface for
/// applying common reshape operations on the mesh, performed on GPU. Additionally, by accessing and
/// updating its \c meshDisplacementTexture any custom displacement map can be set.
@interface LTReshapeProcessor : LTImageProcessor <LTPartialProcessing, LTScreenProcessing>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with an \c input texture an \c output texture and without a freeze
/// mask support. \c meshDisplacementTexture is initialized to an RGBA half float texture of size
/// <tt>std::ceil(input.size / 8) + CGSizeMakeUniform(1)</tt> with zeros.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Initializes the processor with a passthrough fragment shader, an \c input texture, a \c mask
/// which indicates areas to freeze (values lower than \c 1) while adjusting the displacement map
/// texture and an \c output texture to write the results into. \c mask can be set to \c nil for
/// canceling freeze mask support. \c meshDisplacementTexture is initialized to an RGBA half float
/// texture of size <tt>std::ceil(input.size / 8) + CGSizeMakeUniform(1)</tt> with zeros.
- (instancetype)initWithInput:(LTTexture *)input mask:(nullable LTTexture *)mask
                       output:(LTTexture *)output;

/// Initializes the processor with a fragment shader, an \c input texture, a \c mask which indicates
/// areas to freeze (values lower than \c 1) while adjusting the displacement map texture, and an \c
/// output texture to write the results into. \c mask can be set to \c nil for canceling freeze mask
/// support. \c meshDisplacementTexture is initialized to an RGBA half float texture of size
/// <tt>std::ceil(input.size / 8) + CGSizeMakeUniform(1)</tt> with zeros.
- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                                  mask:(nullable LTTexture *)mask output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

/// Clears the displacement map texture with zeros (no displacement).
- (void)resetMesh;

/// Reshape the current mesh at the given center in the given direction according to the given brush
/// parameters, with respect to the current mask.
///
/// @note \c center and \c direction are given in normalized texture coordinates ([0,1]x[0,1]).
- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(const LTReshapeBrushParams &)params;

/// Resizes the current mesh at the given center with the given scale according to the given brush
/// parameters, with respect to the current mask.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(const LTReshapeBrushParams &)params;

/// Unwarps the current mesh at the given center (towards its default state) according to the given
/// brush parameters. The mask (if set) is ignored.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)unwarpWithCenter:(CGPoint)center brushParams:(const LTReshapeBrushParams &)params;

/// Mesh displacement texture used to alter the mesh vertices. The warp applied to the mesh is
/// according to the content of this texture, as offsets (in normalized texture coordinates) of the
/// mesh vertices covering the texture.
///
/// @see \c LTMeshDrawer.
@property (readonly, nonatomic) LTTexture *meshDisplacementTexture;

/// Size of the input texture.
@property (readonly, nonatomic) CGSize inputSize;

/// Size of the output texture.
@property (readonly, nonatomic) CGSize outputSize;

/// Input texture of the processor.
@property (readonly, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (readonly, nonatomic) LTTexture *outputTexture;

@end

NS_ASSUME_NONNULL_END
