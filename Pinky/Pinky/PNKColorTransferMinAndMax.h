// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@protocol MTLBuffer;

/// Computes global minimum and maximum pixel values per each channel for given \c MTLBuffers after
/// a given \c 3x3 linear transformation is applied on them. Inputs are expected to be Float RGBA,
/// and the alpha channel is ignored. The transformation is applied on the fly, such that the input
/// buffers are left unchanged.
API_AVAILABLE(ios(10.0))
@interface PNKColorTransferMinAndMax : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device, and array of boxed \c CGSize with the original dimensions
/// in pixels of the buffers that will be given as input.
- (instancetype)initWithDevice:(id<MTLDevice>)device inputSizes:(NSArray<NSValue *> *)inputSizes
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operations performed by the kernels to \c commandBuffer, using \c inputBuffers as
/// input, applying the \c 3x3 transformation in \c transformBuffer on the fly during the
/// calculation such that they are left unchanged. Global minimum and maximum are written to
/// \c minValueBuffer and \c maxValueBuffer which are expected to contain at least 4 floats due to
/// padding (RGBA, last channel is ignored). Number of pixels in each input buffer should match the
/// \c inputSizes provided during initialization.
///
/// @note \c transformBuffer should represent a 3x3 float matrix in 12 floats due to padding, such
/// that each 4th float is ignored.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputBuffers:(NSArray<id<MTLBuffer>> *)inputBuffers
              transformBuffer:(nullable id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer;

/// Original dimensions in pixels of the input buffers that will be provided.
@property (readonly, nonatomic) NSArray<NSValue *> *inputSizes;

@end

NS_ASSUME_NONNULL_END
