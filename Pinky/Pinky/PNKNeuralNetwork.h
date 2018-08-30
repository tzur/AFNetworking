// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by classes representing a neural network.
API_AVAILABLE(ios(10.0))
@protocol PNKNeuralNetwork <NSObject>

/// Encodes the entire set of operations performed by the neural network onto \c commandBuffer.
/// \c inputImages is a collection of input images mapped by their names. \c outputImages is a
/// collection of output images mapped by their names. \c inputParameters is a collection of input
/// parameters mapped by their names.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages;

/// Array of names of network input images.
@property (readonly, nonatomic) NSArray<NSString *> *inputImageNames;

/// Dictionary that maps input image names to their suggested sizes.
@property (readonly, nonatomic) std::unordered_map<std::string, MTLSize> inputImageNamesToSizes;

/// Array of names of network input parameters.
@property (readonly, nonatomic) NSArray<NSString *> *inputParameterNames;

/// Array of names of network output images.
@property (readonly, nonatomic) NSArray<NSString *> *outputImageNames;

/// Dictionary that maps names of network metadata fields to their values.
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *metadata;

@end

NS_ASSUME_NONNULL_END
