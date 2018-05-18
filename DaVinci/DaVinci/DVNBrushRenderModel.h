// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>
#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushModel, DVNBrushRenderTargetInformation;

/// Value object consisting of the information required to render a brush stroke, as defined by the
/// \c DVNBrushModel class, onto a bound render target.
@interface DVNBrushRenderModel : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c brushModel, \c renderTargetInfo, and
/// \c conversionFactor.
+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                      renderTargetInfo:(DVNBrushRenderTargetInformation *)renderTargetInfo
                      conversionFactor:(CGFloat)conversionFactor;

/// Returns a new instance with the given \c brushModel, \c renderTargetLocation,
/// \c renderTargetHasSingleChannel, \c renderTargetIsNonPremultiplied and \c conversionFactor.
+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                  renderTargetLocation:(lt::Quad)renderTargetLocation
          renderTargetHasSingleChannel:(BOOL)renderTargetHasSingleChannel
        renderTargetIsNonPremultiplied:(BOOL)renderTargetIsNonPremultiplied
                      conversionFactor:(CGFloat)conversionFactor;

/// Model determining the brush to be used for brush stroke rendering.
@property (readonly, nonatomic) DVNBrushModel *brushModel;

/// Information about the render target provided upon initialization.
@property (readonly, nonatomic) DVNBrushRenderTargetInformation *renderTargetInfo;

/// Multiplicative factor converting from inches, used by the \c brushModel of this instance, to
/// units of the coordinate system of the spline along which the brush geometry is to be rendered.
@property (readonly, nonatomic) CGFloat conversionFactor;

@end

NS_ASSUME_NONNULL_END
