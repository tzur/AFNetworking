// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

NS_ASSUME_NONNULL_BEGIN

/// Provides shape model parameters for face given an image and face bounding rect. Face model is
/// derived from Basel 2017 shape model and consist of first \c 80 parameters of shape, first \c 64
/// parameters of expression, first \c 80 parameters of albedo and \c 27 parameters that represent
/// \c 9 first spherical harmonics for each of 3 colour channels.
/// See http://gravis.dmi.unibas.ch/PMM/ for details.
///
/// Resulting parameters vector contains values concatenated together in the order mentioned above
/// followed by \c 3 parameters of rotation in radians, \c 3 of translation and \c 1 for focal
/// length resulting in single vector of \c 258 parameters.
@interface PNKFaceModelProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the network model file. Returns \c nil in case it cannot
/// load the network model from \c networkModelURL, when initialized on a simulator or an
/// unsupported GPU.
- (nullable instancetype)initWithNetworkModelURL:(NSURL *)networkModelURL
                                           error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Fits the parameters of the face shape model given an \c input and \c faceRect specifying the
/// region that contains the face of interest. Writes the fitted parameters to the \c output as a
/// single \c 1x258 vector, then executes the \c completion block. If \c completion block called
/// with failure status the data of the \c output is not modified.
///
/// @param input a pixel buffer of a supported type. Only \c kCVPixelFormatType_32BGRA is supported.
/// \c input should be Metal compatible (IOSurface backed).
///
/// @param output a pointer to matrix to copy the result to. \c output size must be exactly \c 1
/// row by \c 258 columns.
///
/// @param completion a block called on an arbitrary queue to notify on success or failure. If
/// fitting completed succesfully the block is called after the fitted parameters are written to
/// \c output. In case of failure the \c output is not modified. Note that writing to \c input or
/// reading from \c output prior to \c completion being called will lead to undefined behaviour.
- (void)fitFaceParametersWithInput:(CVPixelBufferRef)input output:(cv::Mat1f *)output
                          faceRect:(CGRect)faceRect completion:(LTSuccessOrErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
