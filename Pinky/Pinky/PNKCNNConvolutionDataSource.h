// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct ConvolutionKernelModel;
}

#if PNK_USE_MPS

/// Convolution kernel data source that provides the data from \c pnk::ConvolutionKernelModel and
/// \c pnk::ActivationKernelModel provided on initialization.
API_AVAILABLE(ios(11.0))
@interface PNKCNNConvolutionDataSource : NSObject<MPSCNNConvolutionDataSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a convolution kernel data source with data from \c convolutionModel and
/// \c activationModel.
- (instancetype)initWithConvolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
                         activationModel:(const pnk::ActivationKernelModel &)activationModel
    NS_DESIGNATED_INITIALIZER;

@end

#endif

NS_ASSUME_NONNULL_END
