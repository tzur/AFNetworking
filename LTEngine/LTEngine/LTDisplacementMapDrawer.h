// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTReshapeBrushParams.h"

@class LTFbo, LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Drawer for changing a displacement map texture using some basic common operations.
@interface LTDisplacementMapDrawer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a drawer with a displacement map texture to draw on, the size of the area that the
/// displacement map will deform using \c LTMeshDrawer and without a freeze mask support.
- (instancetype)initWithDisplacementMap:(LTTexture *)displacementMap
                       deformedAreaSize:(CGSize)deformedAreaSize;

/// Initializes a drawer with a displacement map texture to draw on, a mask which indicates areas to
/// freeze (values lower than \c 1) while drawing on the displacement map the size of the area that
/// the displacement map will deform using \c LTMeshDrawer and.
- (instancetype)initWithDisplacementMap:(LTTexture *)displacementMap mask:(LTTexture *)mask
                       deformedAreaSize:(CGSize)deformedAreaSize NS_DESIGNATED_INITIALIZER;

/// Reshape the current displacement map at the given center in the given direction according to the
/// given brush parameters, with respect to the current mask.
///
/// @note \c center and \c direction are given in normalized texture coordinates ([0,1]x[0,1]).
- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(const LTReshapeBrushParams &)params;

/// Resizes the current displacement map at the given center with the given scale according to the
/// given brush parameters, with respect to the current mask.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(const LTReshapeBrushParams &)params;

/// Unwarps the current displacement map at the given center (towards its default state) according
/// to the given brush parameters. The mask (if set) is ignored.
///
/// @note \c center is given in normalized texture coordinates ([0,1]x[0,1]).
- (void)unwarpWithCenter:(CGPoint)center brushParams:(const LTReshapeBrushParams &)params;

/// Resets the displacement map to a neutral state (no displacement).
- (void)resetDisplacementMap;

/// Displacement map texture that is deformed.
@property (readonly, nonatomic) LTTexture *displacementMap;

@end

NS_ASSUME_NONNULL_END
