// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

/// Value object representing properties of a render target onto which brush stroke geometry can be
/// rendered. In particular, the object determines the relation between the brush stroke geometry
/// coordinate system, as defined by \c DVNBrushModel, and the coordinate system of the render
/// target.
@interface DVNBrushRenderTargetInformation : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c renderTargetLocation and
/// \c renderTargetHasSingleChannel indication.
+ (instancetype)instanceWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                    renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel;

/// Location, in units of the brush stroke geometry coordinate system, of the corners of the
/// render target onto which the brush stroke geometry is to be projected.
@property (readonly, nonatomic) lt::Quad renderTargetLocation;

/// Indication whether the render target has a single channel.
@property (readonly, nonatomic) BOOL renderTargetHasSingleChannel;

@end

NS_ASSUME_NONNULL_END
