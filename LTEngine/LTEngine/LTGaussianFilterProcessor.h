// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTSeparableImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Interface for utility class that allows conversion of a texture texel offset step to
/// an absolute value.
@protocol LTGaussianFilterSpatialUnitProvider <NSObject>

/// Returns a unit distance for the conversion from a input texture texel offset index to a
/// coordinate value passed to the convolution kernel shape function (e.g. gaussian). The returned
/// value may depend on the output texture \c size (in pixels) provided.
- (CGFloat)spatialUnitForImageSize:(CGSize)size;

@end

/// Applies a gaussian blur to the input texture.
///
/// The 2D gaussian kernel is perfectly separable into 2 1D kernels, thus the running time of
/// the processor is <tt>O(h * w * numberOfTaps)</tt> where \c h, \c w are the input image
/// dimentions and the \c numberOfTaps is the 1D filter kernel length.
@interface LTGaussianFilterProcessor : LTSeparableImageProcessor

/// Initializes the processor with \c input texture and \c outputs textures.
///
/// @param numberOfTaps number of taps in filter that will be created to approximate the gaussian
/// function. Must be odd and <tt><= [LTGaussianFilterProcessor  maxNumberOfFilterTaps]</tt>.
///
/// All output textures must to be of the same size.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
                 numberOfTaps:(NSUInteger)numberOfTaps
          spatialUnitProvider:(id<LTGaussianFilterSpatialUnitProvider>)spatialUnitProvider
          NS_DESIGNATED_INITIALIZER;

/// Same as above, but provides the default spatial unit provider which produces the convolution
/// kernel of a constant size and shape in pixel units.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
                 numberOfTaps:(NSUInteger)numberOfTaps;

/// Maximum 1D kernel length that can be accepted (imposed by the GPU limitations).
+ (NSUInteger)maxNumberOfFilterTaps;

/// Spatial standard deviation - larger value means a more blurry output. Defaults to \c 1. Must be
/// > \c 0.
@property (nonatomic) CGFloat sigma;
LTPropertyDeclare(CGFloat, sigma, Sigma);

@end

NS_ASSUME_NONNULL_END
