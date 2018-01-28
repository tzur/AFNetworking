// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Node describing a single stage in the neural network scheme.
@interface PNKNeuralNode : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new neural node that wraps a \c unaryKernel. \c primaryInputImageName and
/// \c outputImageName parameters are used to connect this node's input and output with inputs and
/// outputs of other nodes in the same scheme. \c outputImageReadCount parameter designates the
/// \c readCount property value to be set on the output image in case it is of \c MPSTempoarayImage
/// type.
- (instancetype)initWithUnaryKernel:(id<PNKUnaryKernel>)unaryKernel
              primaryInputImageName:(NSString *)primaryInputImageName
                    outputImageName:(NSString *)outputImageName
               outputImageReadCount:(NSUInteger)outputImageReadCount;

/// Initializes a new neural node that wraps a \c binaryKernel. \c primaryInputImageName,
/// \c secondaryInputImageName and \c outputImageName parameters are used to connect this nodes'
/// input and output with inputs and outputs of other nodes in the same scheme.
/// \c outputImageReadCount parameter designates the \c readCount property value to be set on the
/// output image in case it is of \c MPSTempoarayImage type.
- (instancetype)initWithBinaryKernel:(id<PNKBinaryKernel>)binaryKernel
               primaryInputImageName:(NSString *)primaryInputImageName
             secondaryInputImageName:(NSString *)secondaryInputImageName
                     outputImageName:(NSString *)outputImageName
                outputImageReadCount:(NSUInteger)outputImageReadCount;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. \c secondaryInputImage must be \c nil for a node wrapping
/// a unary kernel and non-\c nil for a node wrapping a binary kernel. Output is written
/// asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(nullable MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

/// Determines the size of \c outputImage that fits the size of \c primaryInputImage (for unary
/// kernel) or the sizes of \c primaryInputImage and \c secondaryInputImage (for binary kernel). All
/// parameters of the underlying kernel should be set prior to calling this method in order to
/// receive the correct size.
- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize;

/// Primary input image name as set by initializer.
@property (readonly, nonatomic) NSString *primaryInputImageName;

/// Secondary input image name as set by initializer.
@property (readonly, nonatomic, nullable) NSString *secondaryInputImageName;

/// Output image name as set by initializer.
@property (readonly, nonatomic) NSString *outputImageName;

@end

#endif

NS_ASSUME_NONNULL_END
