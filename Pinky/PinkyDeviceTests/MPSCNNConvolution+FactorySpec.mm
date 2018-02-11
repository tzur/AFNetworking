// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSCNNConvolution+Factory.h"

#import "PNKNeuralNetworkOperationsModel.h"

SpecBegin(MPSCNNConvolution_Factory)

__block id<MTLDevice> device;
__block pnk::ConvolutionKernelModel convolutionKernelModel;
__block pnk::ActivationKernelModel activationKernelModel;
__block MPSCNNConvolution *convolution;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

it(@"should raise when kernel weights count does not match other parameters", ^{
  convolutionKernelModel = {
    .kernelWidth = 3,
    .kernelHeight = 3,
    .kernelChannels = 1,
    .groups = 1,
    .inputFeatureChannels = 1,
    .outputFeatureChannels = 1,
    .strideX = 1,
    .strideY = 1,
    .dilationX = 1,
    .dilationY = 1,
    .padding = pnk::PaddingTypeSame,
    .isDeconvolution = NO,
    .hasBias = NO,
    .deconvolutionOutputSize = CGSizeNull,
    .kernelWeights = cv::Mat1f::ones(5, 5)
  };

  activationKernelModel = {
    .activationType = pnk::ActivationTypeIdentity
  };

  expect(^{
    convolution = [MPSCNNConvolution pnk_cnnConvolutionWithDevice:device
                                                 convolutionModel:convolutionKernelModel
                                                  activationModel:activationKernelModel];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
