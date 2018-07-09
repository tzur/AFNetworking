// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// The processor computes the shift and scale coefficients as a part of the Fast Guided filter
/// method described in the paper (http://arxiv.org/abs/1505.00996). It can be used for various
/// tasks: edge avoiding smoothing, detail enchancement, cross image mask enchancement etc.
/// The processor can accept the same texture as an input and a guide, such flow works faster
/// than the case where the input and the guide are separate textures.
@interface LTGuidedFilterCoefficientsProcessor : LTImageProcessor

/// Initializes the processor with the \c input to smooth and the output texture arrays for scale
/// and shift coefficients and the kernel sizes used for the guided filtering.
///
/// The \c guide and the \c input must be either R or RGBA textures. The combination of R guide and
/// RGBA input is not supported.
///
/// The coefficients textures can be smaller than the \c input texture but must have the same size
/// pairwise for shift and scale coefficients. The aspect ratio of the coefficients textures should
/// be as close as possible to the aspect ratio of \c input to obtain meaningful results.
/// The texture components of the coefficients must be the same as in \c input. If \c input is not
/// the same texture as \c guide, the data type of the coefficients must be half-float since it
/// needs to store values of wider dynamic range which can be also outside of <tt>[0, 1]</tt> range.
///
/// The \c kernelSizes array length must be equal to the \c scaleCoefficients and
/// \c shiftCoefficients arrays length. Each value in \c kernelSizes must be an odd number in
/// <tt>[3, 999]</tt> range.
- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture *)guide
            scaleCoefficients:(NSArray<LTTexture *> *)scaleCoefficients
            shiftCoefficients:(NSArray<LTTexture *> *)shiftCoefficients
                  kernelSizes:(const std::vector<NSUInteger> &)kernelSizes
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Amount of smoothing in the output image. Larger value results in a more aggressive smoothing but
/// ruins edges preservation. Must be in <tt>[1e-7, 1]</tt> range. Default value is \c 0.01.
@property (nonatomic) CGFloat smoothingDegree;
LTPropertyDeclare(CGFloat, smoothingDegree, SmoothingDegree);

@end

NS_ASSUME_NONNULL_END
