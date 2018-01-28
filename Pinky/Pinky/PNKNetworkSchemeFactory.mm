// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNetworkSchemeFactory.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSData+Compression.h>

#import "PNKActivationLayer.h"
#import "PNKAddition.h"
#import "PNKBatchNormalizationLayer.h"
#import "PNKConcatenation.h"
#import "PNKConvolutionLayer.h"
#import "PNKCoreMLLayerParser.h"
#import "PNKInstanceNormLayer.h"
#import "PNKNeuralNetworkOperationsModel.h"
#import "PNKNeuralNode.h"
#import "PNKPoolingLayer.h"
#import "PNKProtobufMacros.h"
#import "PNKSoftMaxLayer.h"
#import "PNKUpsampling.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import "Model.pb.h"
#import "NeuralNetwork.pb.h"
PNK_PROTOBUF_INCLUDE_END

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

namespace cms = CoreML::Specification;

typedef std::vector<const cms::NeuralNetworkLayer *> Layers;
typedef std::unordered_set<const cms::NeuralNetworkLayer *> LayerSet;

namespace pnk {

/// Data for fast navigation in a neural network.
struct NetworkMetadata {
  /// Maps the name of each output image to its corresponding layer.
  std::unordered_map<std::string, const cms::NeuralNetworkLayer *> outputNameToLayer;

  /// Maps the name of each input image to its corresponding layer(s).
  ///
  /// @note A single image can be an input to multiple layers, so the mapping is not necessarily
  /// one-to-one.
  std::unordered_multimap<std::string, const cms::NeuralNetworkLayer *> inputNameToLayers;

  /// Network input images.
  std::unordered_set<std::string> globalInputNames;

  /// Network output images.
  std::unordered_set<std::string> globalOutputNames;
};

/// Intermediate data used by graph traversal algoithm.
struct GraphTraversalData {
  /// Layers not visited yet by the traversal.
  std::unordered_set<const cms::NeuralNetworkLayer *> unvisitedLayers;
  /// Layers visited by the traversal.
  std::unordered_set<const cms::NeuralNetworkLayer *> visitedLayers;
  /// Images processed by the traversal.
  std::unordered_set<std::string> processedImageNames;
};

} // namespace pnk

@implementation PNKNetworkSchemeFactory

+ (std::experimental::optional<pnk::NetworkScheme>)schemeWithDevice:(id<MTLDevice>)device
    coreMLModel:(NSURL *)modelURL
    error:(NSError *__autoreleasing *)error {
  auto _Nullable modelPath = modelURL.path;
  LTParameterAssert(modelPath, @"%@ path is nil", modelURL);
  auto _Nullable inputFile = [[LTMMInputFile alloc] initWithPath:modelPath error:error];
  if (!inputFile) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed url:modelURL];
    }
    return std::experimental::nullopt;
  }

  NSData *inputData = [NSData dataWithBytes:inputFile.data length:inputFile.size];
  NSData * _Nullable data =
      [inputData lt_decompressWithCompressionType:LTCompressionTypeLZFSE error:error];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeCompressionFailed path:modelPath
                             description:@"Failed to decompress data of model file"];
    }
    return std::experimental::nullopt;
  }

  cms::Model networkModel;
  bool parsed = networkModel.ParseFromArray(data.bytes, (int)data.length);
  if (!parsed) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:modelPath
                             description:@"Failed to deserialize data from protobuf model"];
    }
    return std::experimental::nullopt;
  }

  LTParameterAssert(networkModel.has_neuralnetwork(), @"Incorrect model type, expected neural "
                    "network");
  return [self schemeWithDevice:device neuralNetwork:networkModel.neuralnetwork() error:error];
}

+ (std::experimental::optional<pnk::NetworkScheme>)schemeWithDevice:(id<MTLDevice>)device
    neuralNetwork:(const cms::NeuralNetwork &)neuralNetwork
    error:(NSError *__autoreleasing *)error {
  pnk::NetworkMetadata metadata = [self networkMetadataFromNeuralNetwork:neuralNetwork];

  auto orderedLayers = [self orderedLayersFromNeuralNetwork:neuralNetwork metadata:metadata
                                                      error:error];

  if (orderedLayers.size() == 0) {
    return std::experimental::nullopt;
  }

  auto orderedNodeKits = [self orderedNodeKitsFromOrderedLayers:orderedLayers metadata:metadata];

  NSMutableArray<PNKNeuralNode *> *nodes = [NSMutableArray array];

  for (const auto &kit: orderedNodeKits) {
    auto node = [self neuralNodeWithKit:kit device:device metadata:metadata];
    [nodes addObject:node];
  }

  NSMutableArray<NSString *> *inputImageNames = [NSMutableArray array];
  for (const auto &name: metadata.globalInputNames) {
    [inputImageNames addObject:[NSString stringWithUTF8String:name.c_str()]];
  }

  NSMutableArray<NSString *> *outputImageNames = [NSMutableArray array];
  for (const auto &name: metadata.globalOutputNames) {
    [outputImageNames addObject:[NSString stringWithUTF8String:name.c_str()]];
  }

  pnk::NetworkScheme networkScheme = {
    .nodes = nodes,
    .inputImageNames = inputImageNames,
    .outputImageNames = outputImageNames
  };
  return networkScheme;
}

+ (pnk::NetworkMetadata)networkMetadataFromNeuralNetwork:(const cms::NeuralNetwork &)neuralNetwork {
  pnk::NetworkMetadata metadata;

  for (const auto &layer : neuralNetwork.layers()) {
    for (int i = 0; i < layer.input_size(); ++i) {
      metadata.inputNameToLayers.insert(std::make_pair(layer.input(i), &layer));
    }
    metadata.outputNameToLayer[layer.output(0)] = &layer;
  }

  /// Find all input names that are not output names - these are global inputs.
  for (const auto &pair: metadata.inputNameToLayers) {
    if (metadata.outputNameToLayer.find(pair.first) == metadata.outputNameToLayer.end()) {
      metadata.globalInputNames.insert(pair.first);
    }
  }

  /// Find all output names that are not input names - these are global outputs.
  for (const auto &pair: metadata.outputNameToLayer) {
    if (metadata.inputNameToLayers.find(pair.first) == metadata.inputNameToLayers.end()) {
      metadata.globalOutputNames.insert(pair.first);
    }
  }

  return metadata;
}

/// Traverses the network and returns the layers ordered in the proper encoding order.
/// \c neuralNetwork is expected to represent a connected DAG (a directed graph with exactly one
/// connected component and zero cycles). In case \c neuralNetwork does not represent a graph in the
/// expected structure, the function returns an empty vector of layers and fills \c error
/// (if provided).
+ (Layers)orderedLayersFromNeuralNetwork:(const cms::NeuralNetwork &)neuralNetwork
                                metadata:(const pnk::NetworkMetadata &)metadata
                                   error:(NSError *__autoreleasing *)error {
  Layers orderedLayers;
  orderedLayers.reserve(neuralNetwork.layers().size());

  pnk::GraphTraversalData graphTraversalData;
  for (const auto &layer : neuralNetwork.layers()) {
    graphTraversalData.unvisitedLayers.insert(&layer);
  }

  // Initialize the visited layers set with layers that have one of global input images as their
  // inputs.
  for (const auto &inputName: metadata.globalInputNames) {
    [self processImage:inputName metadata:metadata graphTraversalData:graphTraversalData];
  }

  auto currentlyVisitedLayerIterator = graphTraversalData.visitedLayers.begin();
  while (currentlyVisitedLayerIterator != graphTraversalData.visitedLayers.end()) {
    auto currentlyVisitedLayer = *currentlyVisitedLayerIterator;
    bool readyForProcessing = true;
    for (int i = 0; i < currentlyVisitedLayer->input_size(); ++i) {
      const std::string &inputName = currentlyVisitedLayer->input(i);
      readyForProcessing &= (graphTraversalData.processedImageNames.count(inputName) > 0);
    }

    if (!readyForProcessing) {
      ++currentlyVisitedLayerIterator;
      if (currentlyVisitedLayerIterator == graphTraversalData.visitedLayers.end()) {
        if (error) {
          *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                                 description:@"Neural network is not a DAG"];
        }
        return Layers();
      }
      continue;
    }

    orderedLayers.push_back(currentlyVisitedLayer);

    auto outputName = currentlyVisitedLayer->output(0);
    [self processImage:outputName metadata:metadata graphTraversalData:graphTraversalData];

    graphTraversalData.visitedLayers.erase(currentlyVisitedLayerIterator);
    currentlyVisitedLayerIterator = graphTraversalData.visitedLayers.begin();
  }

  if (graphTraversalData.unvisitedLayers.size() > 0) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"Neural network has more than one connected component"];
    }
    return Layers();
  }

  return orderedLayers;
}

+ (void)processImage:(const std::string &)imageName
            metadata:(const pnk::NetworkMetadata &)metadata
  graphTraversalData:(pnk::GraphTraversalData &)graphTraversalData {
  graphTraversalData.processedImageNames.insert(imageName);

  auto range = metadata.inputNameToLayers.equal_range(imageName);
  for (auto iterator = range.first; iterator != range.second; ++iterator) {
    auto layer = iterator->second;
    graphTraversalData.unvisitedLayers.erase(layer);
    graphTraversalData.visitedLayers.insert(layer);
  }
}

+ (std::vector<Layers>)orderedNodeKitsFromOrderedLayers:(const Layers &)orderedLayers
                                               metadata:(const pnk::NetworkMetadata &)metadata {
  std::vector<Layers> orderedNodeKits;
  orderedNodeKits.reserve(orderedLayers.size());
  LayerSet fusedLayers;
  for (const auto layer: orderedLayers) {
    if (fusedLayers.count(layer) > 0) {
      continue;
    }
    Layers kit = [self kitFromLayer:layer fusedLayers:&fusedLayers metadata:metadata];
    orderedNodeKits.push_back(kit);
  }
  return orderedNodeKits;
}

+ (Layers)kitFromLayer:(const cms::NeuralNetworkLayer *)layer
           fusedLayers:(LayerSet *)fusedLayers
              metadata:(const pnk::NetworkMetadata &)metadata {
  Layers kit = {layer};

  while (YES) {
    std::string outputName = kit.back()->output(0);

    if (metadata.inputNameToLayers.count(outputName) != 1) {
      break;
    }

    auto nextLayer = metadata.inputNameToLayers.find(outputName)->second;
    if (![self layerShouldBeFused:nextLayer withKit:kit metadata:metadata]) {
      break;
    }

    kit.push_back(nextLayer);
    fusedLayers->insert(nextLayer);
  }

  return kit;
}

+ (BOOL)layerShouldBeFused:(const cms::NeuralNetworkLayer *)layer withKit:(const Layers &)kit
                  metadata:(const pnk::NetworkMetadata &)metadata {
  if (layer->input_size() != 1) {
    return NO;
  }

  auto inputName = layer->input(0);

  auto previousLayer = kit.back();
  if (previousLayer->output(0) != inputName) {
    return NO;
  }

  if (metadata.inputNameToLayers.count(inputName) > 1) {
    return NO;
  }

  static const std::set<std::pair<cms::NeuralNetworkLayer::LayerCase,
  cms::NeuralNetworkLayer::LayerCase>> kLayerTypePairsForFusion  = {
    {cms::NeuralNetworkLayer::kConvolution, cms::NeuralNetworkLayer::kActivation},
    {cms::NeuralNetworkLayer::kBatchnorm, cms::NeuralNetworkLayer::kActivation}
  };

  return kLayerTypePairsForFusion.count(std::make_pair(previousLayer->layer_case(),
                                                       layer->layer_case())) > 0;
}

+ (PNKNeuralNode *)neuralNodeWithKit:(const Layers &)kit
                              device:(id<MTLDevice>)device
                            metadata:(const pnk::NetworkMetadata &)metadata {
  auto layer = kit[0];
  std::string outputName = kit.back()->output(0);

  NSObject *kernel = nil;

  switch (layer->layer_case()) {
    case cms::NeuralNetworkLayer::kConvolution: {
      pnk::ConvolutionKernelModel convolutionKernelModel =
         pnk::createConvolutionKernelModel(layer->convolution());

      pnk::ActivationKernelModel activationKernelModel =
          (kit.size() == 2 && kit[1]->has_activation()) ?
              pnk::createActivationKernelModel(kit[1]->activation()) :
              pnk::ActivationKernelModel{.activationType = pnk::ActivationTypeIdentity};

      kernel = [[PNKConvolutionLayer alloc] initWithDevice:device
                                          convolutionModel:convolutionKernelModel
                                           activationModel:activationKernelModel];
    } break;
    case cms::NeuralNetworkLayer::kPooling: {
      pnk::PoolingKernelModel poolingKernelModel =
          pnk::createPoolingKernelModel(layer->pooling());
      kernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingKernelModel];
    } break;
    case cms::NeuralNetworkLayer::kActivation: {
      pnk::ActivationKernelModel activationKernelModel =
          pnk::createActivationKernelModel(layer->activation());
      kernel = [[PNKActivationLayer alloc] initWithDevice:device
                                          activationModel:activationKernelModel];
    } break;
    case cms::NeuralNetworkLayer::kBatchnorm: {
      pnk::NormalizationKernelModel normalizationKernelModel =
          pnk::createNormalizationKernelModel(layer->batchnorm());

      pnk::ActivationKernelModel activationKernelModel =
          (kit.size() == 2 && kit[1]->has_activation()) ?
          pnk::createActivationKernelModel(kit[1]->activation()) :
          pnk::ActivationKernelModel{.activationType = pnk::ActivationTypeIdentity};
      if (normalizationKernelModel.instanceNormalization) {
        kernel = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                           normalizationModel:normalizationKernelModel
                                              activationModel:activationKernelModel];
      } else {
        kernel = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                 normalizationModel:normalizationKernelModel
                                                    activationModel:activationKernelModel];
      }
    } break;
    case cms::NeuralNetworkLayer::kSoftmax:
      kernel = [[PNKSoftMaxLayer alloc] initWithDevice:device];
      break;
    case cms::NeuralNetworkLayer::kUpsample: {
      kernel = [[PNKUpsampling alloc] initWithDevice:device
                                      upsamplingType:PNKUpsamplingTypeNearestNeighbor];
    } break;
    case cms::NeuralNetworkLayer::kAdd:
      kernel = [[PNKAddition alloc] initWithDevice:device];
      break;
    case cms::NeuralNetworkLayer::kConcat:
      kernel = [[PNKConcatenation alloc] initWithDevice:device];
      break;
    case cms::NeuralNetworkLayer::kCustom: {
      kernel = [self customKernelFromLayer:layer device:device];
    } break;
    default:
      LTAssert(NO, @"Layer type %lu not supported", (unsigned long)layer->layer_case());
      break;
  }

  NSString *primaryInputImageName = [NSString stringWithUTF8String:layer->input(0).c_str()];
  NSString *outputImageName = [NSString stringWithUTF8String:outputName.c_str()];
  NSUInteger outputImageReadCount = metadata.inputNameToLayers.count(outputName);

  if ([kernel conformsToProtocol:@protocol(PNKUnaryKernel)]) {
    return [[PNKNeuralNode alloc] initWithUnaryKernel:(id<PNKUnaryKernel>)kernel
                                primaryInputImageName:primaryInputImageName
                                      outputImageName:outputImageName
                                 outputImageReadCount:outputImageReadCount];
  } else if ([kernel conformsToProtocol:@protocol(PNKBinaryKernel)]){
    NSString *secondaryInputImageName = [NSString stringWithUTF8String:layer->input(1).c_str()];
    return [[PNKNeuralNode alloc] initWithBinaryKernel:(id<PNKBinaryKernel>)kernel
                                 primaryInputImageName:primaryInputImageName
                               secondaryInputImageName:secondaryInputImageName
                                       outputImageName:outputImageName
                                  outputImageReadCount:outputImageReadCount];
  } else {
    LTAssert(NO, @"Kernel must conform to either PNKUnaryKernel or PNKBinaryKernel proocol");
  }
}

+ (NSObject *)customKernelFromLayer:(const cms::NeuralNetworkLayer *)layer
                             device:(id<MTLDevice>)device {
  if (layer->custom().classname() == "BilinearUpsample") {
    return [[PNKUpsampling alloc] initWithDevice:device
                                  upsamplingType:PNKUpsamplingTypeBilinearAligned];
  } else {
    LTAssert(NO, @"Custom layer type %s not supported",
             layer->custom().classname().substr(0, 20).c_str());
  }
}

@end

#endif

NS_ASSUME_NONNULL_END
