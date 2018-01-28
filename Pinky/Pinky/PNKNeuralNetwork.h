// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Protocol implemented by classes representing a neural network.
@protocol PNKNeuralNetwork <NSObject>

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
/// \c inputImages is a collection of input images mapped by their names. \c outputImages is a
/// collection of output images mapped by their names.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages;
;

/// Encodes and commits the entire set of operations performed by the neural network onto one or
/// more command buffers derived from \c queue. This method returns immediately and calls
/// \c completion on an arbitrary queue when all operations have been completed. Networks may use
/// this method to implement optimizations not possible by encoding the entire network onto a single
/// command buffer, such as double buffering and CPU-GPU synchronization optimizations.
/// \c inputImages is a collection of input images mapped by their names. \c outputImages is a
/// collection of output images mapped by their names.
- (void)encodeAndCommitAsyncWithCommandQueue:(id<MTLCommandQueue>)queue
                                 inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                                outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages
                                  completion:(LTCompletionBlock)completion;

/// Array of names of network input images.
@property (readonly, nonatomic) NSArray<NSString *> *inputImageNames;

/// Array of names of network output images.
@property (readonly, nonatomic) NSArray<NSString *> *outputImageNames;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
