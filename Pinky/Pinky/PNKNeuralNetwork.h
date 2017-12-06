// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Protocol implemented by classes representing a neural network.
@protocol PNKNeuralNetwork <NSObject>

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage;

/// Encodes and commits the entire set of operations performed by the neural network onto one or
/// more command buffers derived from \c queue. This method returns immediately and calls
/// \c completion on an arbitrary queue when all operations have been completed. Networks may use
/// this method to implement optimizations not possible by encoding the entire network onto a single
/// command buffer, such as double buffering and CPU-GPU synchronization optimizations.
- (void)encodeAndCommitAsyncWithCommandQueue:(id<MTLCommandQueue>)queue
                                  inputImage:(MPSImage *)inputImage
                                 outputImage:(MPSImage *)outputImage
                                  completion:(LTCompletionBlock)completion;

/// Returns the optimal size for an image of a given \c size to be resized to in order to be used as
/// an input image for the network. Optimality is in the sense of the task which the network is
/// meant to perform and not in terms of runtime.
- (CGSize)optimalInputSizeWithSize:(CGSize)size;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
