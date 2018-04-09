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

/// Creates a new \c MPSImage for use on \c device with \c MPSImageFeatureChannelFormatFloat16 as
/// the channel format and given \c size. The new image is then filled with zeroes.
MPSImage *PNKImageMakeAndClearHalf(id<MTLDevice> device, MTLSize size);

/// Reads an array of float32 numbers from \c resource and returns them as a row vector.
cv::Mat1f PNKLoadFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource);

/// Reads an array of float16 numbers from \c resource and returns them as a row vector.
cv::Mat1hf PNKLoadHalfFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource);

/// Reads an array of float16 numbers from \c resource and returns them as a matrix with dimensions
/// defined by \c resource. \c resource must be in the form
/// <tt><some text>_<width>x<height>x<depth>.<extension></tt>. The number of half-floats in
/// \c resource must equal <tt>width * height * depth</tt> as extracted from the name.
cv::Mat PNKLoadStructuredHalfFloatTensorFromResource(NSBundle *bundle, NSString *resource);

/// Creates a half-float matrix with given \c rows, \c columns and \c channels and fills it with
/// zeroes and ones in 3D chessboard pattern.
cv::Mat PNKFillMatrix(int rows, int columns, int channels);

/// Create a matrix of type \c T with given \c rows and \c columns and a number of channels as
/// the size of \c values. Each channel of the matrix has a constant value as defined by \c values.
template <typename T>
cv::Mat PNKGenerateChannelwiseConstantMatrix(NSUInteger rows, NSUInteger columns,
                                             const std::vector<T> &values);

/// Returns the \c MPSImageFeatureChannelFormat matching the Open CV type \c type.
MPSImageFeatureChannelFormat PNKFeatureChannelFormatFromCVType(int type);

NS_ASSUME_NONNULL_END
