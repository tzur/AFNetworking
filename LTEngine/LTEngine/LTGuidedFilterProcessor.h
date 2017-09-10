// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// The processor does an edge-preserving image smoothing as described in the Fast Guided filter
/// paper (http://arxiv.org/abs/1505.00996). It can be used for various tasks: edge avoiding
/// smoothing, detail enchancement, cross image mask enchancement etc. The processor can accept
/// the same texture as an input and a guide, such flow works faster than the case where the input
/// and the guide are separate textures.
@interface LTGuidedFilterProcessor : LTImageProcessor

/// Initializes the processor with the \c input to smooth, filter \c guide, down scale factor of
/// the shift and scale coefficients size, size for rectangular neighborhoods used in the guided
/// filtering and the \c output to store the smoothed image.
///
/// The \c guide and the \c input must be either R or RGBA textures. The combination of R guide and
/// RGBA input is not supported.
///
/// \c kernelSize must be odd and in<tt>[3, 999]</tt> range.
- (instancetype)initWithInput:(LTTexture *)input
                        guide:(LTTexture *)guide
              downscaleFactor:(NSUInteger)downscaleFactor
                   kernelSize:(NSUInteger)kernelSize
                       output:(LTTexture *)output NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Amount of smoothing in the output image. Larger value results in a more aggressive smoothing but
/// ruins edge preservation. Must be in <tt>[1e-7, 1]</tt> range. Default value is 0.01.
@property (nonatomic) CGFloat smoothingDegree;
LTPropertyDeclare(CGFloat, smoothingDegree, SmoothingDegree);

@end

NS_ASSUME_NONNULL_END
