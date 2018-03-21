// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

/// Value object representing properties of a render target onto which brush stroke geometry can be
/// rendered along a spline. In particular, the object determines the relation between the
/// coordinate system of aforementioned spline and the coordinate system of the render target.
/// Additionally, it defines properties of the render target potentially relevant for objects
/// performing the actual rendering.
@interface DVNBrushRenderTargetInformation : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c renderTargetLocation, \c renderTargetHasSingleChannel
/// indication, and \c renderTargetIsNonPremultiplied indication.
+ (instancetype)instanceWithRenderTargetLocation:(lt::Quad)renderTargetLocation
                    renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel
                  renderTargetIsNonPremultiplied:(BOOL)renderTargetIsNonPremultiplied;

/// Location, in units of the spline coordinate system, of the corners of the render target onto
/// which the brush stroke geometry is to be projected.
@property (readonly, nonatomic) lt::Quad renderTargetLocation;

/// Indication whether the render target has a single channel.
@property (readonly, nonatomic) BOOL renderTargetHasSingleChannel;

/// Indication whether the render target is non-premultiplied.
@property (readonly, nonatomic) BOOL renderTargetIsNonPremultiplied;

@end

NS_ASSUME_NONNULL_END
