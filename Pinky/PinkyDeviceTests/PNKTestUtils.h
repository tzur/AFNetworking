// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

/// Creates a new \c MPSImage for use on \c device with the given \c format and given \c width,
/// \c height and \c channels.
MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels);

/// Creates a new \c MPSImage for use on \c device with \c MPSImageFeatureChannelFormatUnorm8 as the
/// channel format and given \c width, \c height and \c channels.
MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels);

/// Reads an array of float32 numbers from \c fileName and returns them as a row vector.
cv::Mat1f PNKLoadFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource);

/// Reads an array of float16 numbers from \c fileName and returns them as a row vector.
cv::Mat1hf PNKLoadHalfFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource);

/// Creates a half-float matrix with given \c rows, \c columns and \c channels and fills it with
/// zeroes and ones in 3D chessboard pattern.
cv::Mat PNKFillMatrix(int rows, int columns, int channels);

/// Creates a uchar matrix with given \c rows and \c columns and a number of channels as the size of
/// \c values. Each channel of the matrix has a constant value as defined by \c values.
cv::Mat PNKGenerateChannelwiseConstantUcharMatrix(NSUInteger rows, NSUInteger columns,
                                                  const std::vector<uchar> &values);

/// Creates a half-float matrix with given \c rows and \c columns and a number of channels as the
/// size of \c values. Each channel of the matrix has a constant value as defined by \c values.
cv::Mat PNKGenerateChannelwiseConstantHalfFloatMatrix(NSUInteger rows, NSUInteger columns,
                                                      const std::vector<half_float::half> &values);

NS_ASSUME_NONNULL_END
