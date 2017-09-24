// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <experimental/optional>

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct NeuralNetworkModel;
}

/// Protocol to be implemented by objects creating \c PNKNeuralNetworkModel from serialized versions
/// of the model.
@protocol PNKNeuralNetworkModelFactory <NSObject>

/// Returns a \c NeuralNetworkModel deserialized from a model file describing a neural network.
/// The serialized model must conform to the extended CoreML model specification and be compressed
/// using LZFSE. Upon successful deserialization, the deserialized neural network model is returned.
/// If an error occurred, an empty optional is returned and \c error is populated with
/// \c LTErrorCodeObjectCreationFailed if the underlying serialized data structure is invalid or
/// \c LTErrorCodeCompressionFailed if decompressing the serialized data has failed.
- (std::experimental::optional<pnk::NeuralNetworkModel>)modelWithCoreMLModel:(NSURL *)modelURL
   error:(NSError **)error;

@end

/// Factory to instantiate \c PNKNeuralNetworkModel from serialized versions of the model.
@interface PNKNeuralNetworkModelFactory : NSObject <PNKNeuralNetworkModelFactory>
@end

NS_ASSUME_NONNULL_END
