// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <experimental/optional>

NS_ASSUME_NONNULL_BEGIN

@class PNKNeuralNode;

namespace pnk {

/// Neural network data ready for run.
struct NetworkScheme {
  /// Array of neural nodes sorted in the order of their encoding.
  NSArray<PNKNeuralNode *> *nodes;

  /// Dictionary that maps names of network input images to their respective read counts.
  NSDictionary<NSString *, NSNumber *> *inputImagesData;

  /// Dictionary that maps input image names to their suggested sizes.
  std::unordered_map<std::string, MTLSize> inputImageNamesToSizes;

  /// Array of names of network output images.
  NSArray<NSString *> *outputImageNames;

  /// Array of names of network input parameters. While input images and output images are
  /// 3-dimensional tensors in Tensorflow and \c MPSImages in Pinky, input parameters can have any
  /// (non-image) type.
  NSArray<NSString *> *inputParameterNames;

  /// Dictionary that maps names of network metadata fields to their values.
  NSDictionary<NSString *, NSString *> *metadata;
};

} // namespace pnk

/// Factory that deserializes a neural network model, creates its corresponding nodes and orders
/// them in the proper encoding order to instantiate a \c pnk::NetworkScheme.
API_AVAILABLE(ios(10.0))
@interface PNKNetworkSchemeFactory : NSObject

/// Builds a network scheme from a serialized model found at \c modelURL. The network scheme is a
/// struct containing information regarding the neural network graph, mainly supported by an array
/// of nodes ordered in the proper encoding order. Each node wraps a kernel that runs on \c device.
/// In case of an error an empty optional will be returned and \c error will be filled (if provided
/// by caller).
///
/// This API can returns the next error codes:
///
/// \c LTErrorCodeFileReadFailed - \c coreMLModel URL is invalid
///
/// \c LTCompressionTypeLZFSE - \c coreMLModel file was not compressed with LZFSE
///
/// \c LTErrorCodeDecryptionFailed - \c coreMLModel file is not a valid CoreML serialization
///
/// \c LTErrorCodeInvalidArgument - the graph represented by \c coreMLModel is either not a fully
/// connected graph or not a DAG (directed acyclic graph).
+ (std::experimental::optional<pnk::NetworkScheme>)schemeWithDevice:(id<MTLDevice>)device
                                                        coreMLModel:(NSURL *)modelURL
                                                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
