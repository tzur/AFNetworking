// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkModelFactory.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSData+Compression.h>

#import "PNKCoreMLLayerParser.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKProtobufMacros.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import "Model.pb.h"
#import "NeuralNetwork.pb.h"
PNK_PROTOBUF_INCLUDE_END

NS_ASSUME_NONNULL_BEGIN

@implementation PNKNeuralNetworkModelFactory

std::unordered_map<std::string, std::string> createNetworkMetadata
    (const CoreML::Specification::Model &networkModel) {
  if (!networkModel.has_description() || !networkModel.description().has_metadata()) {
    return std::unordered_map<std::string, std::string>();
  }
  auto metadata = networkModel.description().metadata();
  google::protobuf::Map<std::string, std::string> userdefinedMetaData = metadata.userdefined();
  auto networkMetadata = std::unordered_map<std::string, std::string>(userdefinedMetaData.begin(),
                                                                      userdefinedMetaData.end());
  if (metadata.shortdescription().length() > 0) {
    networkMetadata["shortdescription"] = metadata.shortdescription();
  }
  if (metadata.versionstring().length() > 0) {
    networkMetadata["versionstring"] = metadata.versionstring();
  }
  if (metadata.author().length() > 0) {
    networkMetadata["author"] = metadata.author();
  }
  if (metadata.license().length() > 0) {
    networkMetadata["license"] = metadata.license();
  }
  return networkMetadata;
}

std::experimental::optional<pnk::ImageScaleBiasModel> createPreprocessingModel
    (const CoreML::Specification::NeuralNetwork &neuralNetwork) {
  LTParameterAssert(neuralNetwork.preprocessing_size() == 0 ||
                    neuralNetwork.preprocessing_size() == 1, @"Multiple preprocessing layers are "
                    "not supported. Received %d preprocessing layers",
                    neuralNetwork.preprocessing_size());

  if (!neuralNetwork.preprocessing_size()) {
    return {};
  }

  auto networkPreprocessing = neuralNetwork.preprocessing(0);
  LTParameterAssert(networkPreprocessing.has_scaler(), @"Preprocessing models other than the "
                    "Scaler model are not supported");

  return pnk::createScaleBiasModel(networkPreprocessing.scaler());
}

pnk::NeuralNetworkModel createNeuralNetworkModel
    (const CoreML::Specification::NeuralNetwork &neuralNetwork,
     const CoreML::Specification::Model &networkModel) {
  using CoreML::Specification::NeuralNetworkLayer;

  std::unordered_map<std::string, pnk::ConvolutionKernelModel> convolutionKernels;
  std::unordered_map<std::string, pnk::PoolingKernelModel> poolingKernels;
  std::unordered_map<std::string, pnk::AffineKernelModel> affineKernels;
  std::unordered_map<std::string, pnk::ActivationKernelModel> activationKernels;
  std::unordered_map<std::string, pnk::NormalizationKernelModel> normalizationKernels;

  for (const auto &layer : neuralNetwork.layers()) {
    switch (layer.layer_case()) {
      case NeuralNetworkLayer::kConvolution:
        convolutionKernels[layer.name()] = pnk::createConvolutionKernelModel(layer.convolution());
        break;
      case NeuralNetworkLayer::kPooling:
        poolingKernels[layer.name()] = pnk::createPoolingKernelModel(layer.pooling());
        break;
      case NeuralNetworkLayer::kActivation:
        activationKernels[layer.name()] = pnk::createActivationKernelModel(layer.activation());
        break;
      case NeuralNetworkLayer::kInnerProduct:
        affineKernels[layer.name()] = pnk::createAffineKernelModel(layer.innerproduct());
        break;
      case NeuralNetworkLayer::kBatchnorm:
        normalizationKernels[layer.name()] = pnk::createNormalizationKernelModel(layer.batchnorm());
        break;
      default:
        // Other layers are part of the network structure, or just not used in model.
        break;
    }
  }

  return {
    .scaleBiasModel = createPreprocessingModel(neuralNetwork),
    .convolutionKernels = convolutionKernels,
    .poolingKernels = poolingKernels,
    .affineKernels = affineKernels,
    .activationKernels = activationKernels,
    .normalizationKernels = normalizationKernels,
    .networkMetadata = createNetworkMetadata(networkModel)
  };
}

- (std::experimental::optional<pnk::NeuralNetworkModel>)modelWithCoreMLModel:(NSURL *)modelURL
   error:(NSError *__autoreleasing *)error {
  auto _Nullable modelPath = modelURL.path;
  LTParameterAssert(modelPath, @"%@ path is nil", modelURL);
  LTMMInputFile * _Nullable inputFile =
      [[LTMMInputFile alloc] initWithPath:modelPath error:error];
  if (!inputFile) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed url:modelURL];
    }
    return {};
  }

  NSData *inputData = [NSData dataWithBytes:inputFile.data length:inputFile.size];
  NSData * _Nullable data =
      [inputData lt_decompressWithCompressionType:LTCompressionTypeLZFSE error:error];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed path:modelPath
                             description:@"Failed to decompress data of model file"];
    }
    return {};
  }

  CoreML::Specification::Model networkModel;
  bool parsed = networkModel.ParseFromArray(data.bytes, (int)data.length);
  if (!parsed) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:modelPath
                             description:@"Failed to deserialize data from protobuf model"];
    }
    return {};
  }

  LTParameterAssert(networkModel.has_neuralnetwork(), @"Incorrect model type, expected neural "
                    "network");
  return createNeuralNetworkModel(networkModel.neuralnetwork(), networkModel);
}

@end

NS_ASSUME_NONNULL_END
