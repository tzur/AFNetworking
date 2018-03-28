// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "PNKNeuralNetworkModelFactory.h"

#import <LTKit/NSBundle+Path.h>
#import <LTKitTestUtils/NSBundle+Test.h>

#import "PNKNeuralNetworkmodel.h"

SpecBegin(PNKNeuralNetworkModelFactory)

context(@"deserialization", ^{
  static const NSUInteger kNumberOfColorChannels = 4;

  __block PNKNeuralNetworkModelFactory *neuralNetworkModelFactory;

  beforeEach(^{
    neuralNetworkModelFactory = [[PNKNeuralNetworkModelFactory alloc] init];
  });

  it(@"should error if the URL is not found", ^{
    NSError *error;
    auto model = [neuralNetworkModelFactory modelWithCoreMLModel:[NSURL URLWithString:@"foo"]
                                                           error:&error];
    expect((bool)model).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });

  it(@"should error if the URL is for an illegal CoreML", ^{
    auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"illegal.nnmodel"]];
    NSError *error;
    auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL
                                                           error:&error];
    expect((bool)model).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeCompressionFailed);

  });

  context(@"scaling and bias model", ^{
    it(@"should deserialize with RGB bias", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle
                                lt_pathForResource:@"conv_rgb_bias_preprocessing.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->scaleBiasModel->channelScale).to.equal(1.0 / 255.0);
      expect(model->scaleBiasModel->blueBias).to.equal(0.3);
      expect(model->scaleBiasModel->greenBias).to.equal(0.7);
      expect(model->scaleBiasModel->redBias).to.equal(0.4);
      expect(model->scaleBiasModel->grayBias).to.equal(0);
    });

    it(@"should deserialize with gray bias", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle
                                lt_pathForResource:@"prelu_gray_bias_preprocessing.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->scaleBiasModel->channelScale).to.equal(1);
      expect(model->scaleBiasModel->blueBias).to.equal(0);
      expect(model->scaleBiasModel->greenBias).to.equal(0);
      expect(model->scaleBiasModel->redBias).to.equal(0);
      expect(model->scaleBiasModel->grayBias).to.equal(123);
    });
  });

  context(@"metadata", ^{
    it(@"should deserialize with metadata", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"metadata.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      auto metadata = model->networkMetadata;
      expect(metadata.size()).to.equal(4);
      expect(@(metadata.at("author").c_str())).to.equal(@"Test");
      expect(@(metadata.at("license").c_str())).to.equal(@"None");
      expect(@(metadata.at("shortdescription").c_str())).to.equal(@"Test modules");
      expect(@(metadata.at("test_key").c_str())).to.equal(@"test_value");
    });
  });

  context(@"convolution", ^{
    it(@"should deserialize with bias", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle
                                lt_pathForResource:@"conv_rgb_bias_preprocessing.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(1);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(0);
      expect(model->normalizationKernels.size()).to.equal(0);

      std::string layerName = "test_conv_activation_None_biasTrue_type_name-strided_kernel-95_"
          "stride-22_dilation-1_pad_same";
      pnk::ConvolutionKernelModel kernelModel = model->convolutionKernels[layerName];
      expect(kernelModel.kernelWidth).to.equal(5);
      expect(kernelModel.kernelHeight).to.equal(9);
      expect(kernelModel.kernelChannels).to.equal(3);
      expect(kernelModel.groups).to.equal(1);
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.outputFeatureChannels).to.equal(4);
      expect(kernelModel.strideX).to.equal(2);
      expect(kernelModel.strideY).to.equal(2);
      expect(kernelModel.dilationX).to.equal(1);
      expect(kernelModel.dilationY).to.equal(1);
      expect(kernelModel.padding).to.equal(pnk::PaddingTypeSame);
      expect(kernelModel.isDeconvolution).to.beFalsy();

      expect(kernelModel.kernelWeights.total()).to.equal(kernelModel.kernelWidth *
                                                         kernelModel.kernelHeight *
                                                         kernelModel.kernelChannels *
                                                         kNumberOfColorChannels);

      int sampleIndicesArray[] = {0, 1, 2, 5, 45, 345};
      float expectedArray[] = {0, 4, 8, 20, 180, 302};
      for (NSUInteger i = 0; i < sizeof(sampleIndicesArray) / sizeof(int); ++i) {
        float kernelWeight = kernelModel.kernelWeights(sampleIndicesArray[i]);
        expect(kernelWeight).to.equal(expectedArray[i]);
      }

      expect(kernelModel.hasBias).to.beTruthy();
      expect(kernelModel.biasWeights.total()).to.equal(kernelModel.outputFeatureChannels);

      int biassampleIndicesArray[] = {0, 1, 2, 3};
      float expectedBiasArray[] = {540, 541, 542, 543};
      for (NSUInteger i = 0; i < sizeof(biassampleIndicesArray) / sizeof(int); ++i) {
        float biasWeight = kernelModel.biasWeights(biassampleIndicesArray[i]);
        expect(biasWeight).to.equal(expectedBiasArray[i]);
      }
    });

    it(@"should deserialize with no bias", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"conv_no_bias.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(1);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(0);
      expect(model->normalizationKernels.size()).to.equal(0);

      std::string layerName = "test_conv_activation_None_biasFalse_type_name-dilated_kernel-33"
          "_stride-11_dilation-4_pad_valid";
      pnk::ConvolutionKernelModel kernelModel = model->convolutionKernels[layerName];
      expect(kernelModel.kernelWidth).to.equal(3);
      expect(kernelModel.kernelHeight).to.equal(3);
      expect(kernelModel.kernelChannels).to.equal(3);
      expect(kernelModel.groups).to.equal(1);
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.outputFeatureChannels).to.equal(4);
      expect(kernelModel.strideX).to.equal(1);
      expect(kernelModel.strideY).to.equal(1);
      expect(kernelModel.dilationX).to.equal(4);
      expect(kernelModel.dilationY).to.equal(4);
      expect(kernelModel.padding).to.equal(pnk::PaddingTypeValid);
      expect(kernelModel.isDeconvolution).to.beFalsy();

      expect(kernelModel.kernelWeights.total()).to.equal(kernelModel.kernelWidth *
                                                         kernelModel.kernelHeight *
                                                         kernelModel.kernelChannels *
                                                         kNumberOfColorChannels);

      int sampleIndicesArray[] = {0, 1, 2, 5, 45};
      float expectedArray[] = {0, 4, 8, 20, 73};
      for (NSUInteger i = 0; i < sizeof(sampleIndicesArray) / sizeof(int); ++i) {
        float kernelWeight = kernelModel.kernelWeights(sampleIndicesArray[i]);
        expect(kernelWeight).to.equal(expectedArray[i]);
      }

      expect(kernelModel.hasBias).to.beFalsy();
    });

    it(@"should deserialize deconvolution", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"deconv.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(1);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(0);
      expect(model->normalizationKernels.size()).to.equal(0);

      std::string layerName = "test_conv_activation_None_biasFalse_type_name-dconv_kernel-44"
          "_stride-22_dilation-1_pad_same";
      pnk::ConvolutionKernelModel kernelModel = model->convolutionKernels[layerName];
      expect(kernelModel.kernelWidth).to.equal(4);
      expect(kernelModel.kernelHeight).to.equal(4);
      expect(kernelModel.kernelChannels).to.equal(3);
      expect(kernelModel.groups).to.equal(1);
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.outputFeatureChannels).to.equal(4);
      expect(kernelModel.strideX).to.equal(2);
      expect(kernelModel.strideY).to.equal(2);
      expect(kernelModel.dilationX).to.equal(1);
      expect(kernelModel.dilationY).to.equal(1);
      expect(kernelModel.padding).to.equal(pnk::PaddingTypeSame);
      expect(kernelModel.isDeconvolution).to.beTruthy();
      expect(kernelModel.deconvolutionOutputSize.height).to.equal(64);
      expect(kernelModel.deconvolutionOutputSize.width).to.equal(64);

      expect(kernelModel.kernelWeights.total()).to.equal(kernelModel.kernelWidth *
                                                         kernelModel.kernelHeight *
                                                         kernelModel.kernelChannels *
                                                         kNumberOfColorChannels);

      int sampleIndicesArray[] = {0, 1, 2, 5, 45};
      float expectedArray[] = {0, 3, 6, 18, 180};
      for (NSUInteger i = 0; i < sizeof(sampleIndicesArray) / sizeof(int); ++i) {
        float kernelWeight = kernelModel.kernelWeights(sampleIndicesArray[i]);
        expect(kernelWeight).to.equal(expectedArray[i]);
      }

      expect(kernelModel.hasBias).to.beFalsy();
    });
  });

  context(@"activation", ^{
    it(@"should deserialize prelu", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle
                                lt_pathForResource:@"prelu_gray_bias_preprocessing.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(0);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(1);
      expect(model->normalizationKernels.size()).to.equal(0);

      std::string layerName = "p_re_lu_1";
      pnk::ActivationKernelModel kernelModel = model->activationKernels[layerName];
      expect(kernelModel.activationType).to.equal(pnk::ActivationTypePReLU);
      expect(kernelModel.alpha.total()).to.equal(3);

      cv::Mat1f expected = (cv::Mat1f(1, 3) << 0, 1, 2);
      expect($(kernelModel.alpha)).to.equalMat($(expected));
    });
  });

  context(@"pooling", ^{
    it(@"should deserialize max pool", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"maxpool.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(0);
      expect(model->poolingKernels.size()).to.equal(1);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(0);
      expect(model->normalizationKernels.size()).to.equal(0);

      pnk::PoolingKernelModel kernelModel = model->poolingKernels["test_maxpool"];
      expect(kernelModel.pooling).to.equal(pnk::PoolingTypeMax);
      expect(kernelModel.kernelWidth).to.equal(3);
      expect(kernelModel.kernelHeight).to.equal(2);
      expect(kernelModel.strideX).to.equal(3);
      expect(kernelModel.strideY).to.equal(2);
      expect(kernelModel.padding).to.equal(pnk::PaddingTypeValid);
      expect(kernelModel.averagePoolExcludePadding).to.beTruthy();
      expect(kernelModel.globalPooling).to.beFalsy();
    });
  });

  context(@"affine", ^{
    it(@"should deserialize affine", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"affine.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      expect(model->convolutionKernels.size()).to.equal(0);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(1);
      expect(model->activationKernels.size()).to.equal(0);
      expect(model->normalizationKernels.size()).to.equal(0);

      std::string layerName = "dense_1";
      pnk::AffineKernelModel kernelModel = model->affineKernels[layerName];
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.outputFeatureChannels).to.equal(5);
      expect(kernelModel.kernelWeights.total()).to.equal(kernelModel.inputFeatureChannels *
                                                         kernelModel.outputFeatureChannels);
      int sampleIndicesArray[] = {0, 10, 5};
      float expectedArray[] = {0, 8, 11};
      for (NSUInteger i = 0; i < sizeof(sampleIndicesArray) / sizeof(int); ++i) {
        float kernelWeight = kernelModel.kernelWeights(sampleIndicesArray[i]);
        expect(kernelWeight).to.equal(expectedArray[i]);
      }

      expect(kernelModel.hasBias).to.beTruthy();
      expect(kernelModel.biasWeights.total()).to.equal(kernelModel.outputFeatureChannels);
      int biasSampleIndicesArray[] = {0, 1, 2, 3, 4};
      float expectedBiasArray[] = {15, 16, 17, 18, 19};
      for (NSUInteger i = 0; i < sizeof(biasSampleIndicesArray) / sizeof(int); ++i) {
        float biasWeight = kernelModel.biasWeights(biasSampleIndicesArray[i]);
        expect(biasWeight).to.equal(expectedBiasArray[i]);
      }
    });
  });

  context(@"Normalization", ^{
    it(@"should deserialize batch normalization", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"batchnorm.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      auto convolutionKernelsSize = model->convolutionKernels.size();
      expect(convolutionKernelsSize).to.equal(0);
      auto poolingKernelsSize = model->poolingKernels.size();
      expect(poolingKernelsSize).to.equal(0);
      auto affineKernelsSize = model->affineKernels.size();
      expect(affineKernelsSize).to.equal(0);
      auto activationKernelsSize = model->activationKernels.size();
      expect(activationKernelsSize).to.equal(0);
      auto normalizationKernelsSize = model->normalizationKernels.size();
      expect(normalizationKernelsSize).to.equal(1);

      cv::Mat1f expectedScale = (cv::Mat1f(1, 3) << 0, 0.3162119686603546, 0.6029952764511108);
      cv::Mat1f expectedShift = (cv::Mat1f(1, 3) << 3, 1.7865161895751953, 0.17603778839111328);
      cv::Mat1f expectedMean(1, 3, 0.);
      cv::Mat1f expectedVariance(1, 3, 0.9999899864196777);

      std::string layerName = "batch_normalization_1";
      pnk::NormalizationKernelModel kernelModel = model->normalizationKernels[layerName];
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.computeMeanVar).to.beFalsy();
      expect(kernelModel.instanceNormalization).to.beFalsy();
      expect(kernelModel.epsilon).to.equal(0.00001);
      expect($(kernelModel.scale)).to.equalMat($(expectedScale));
      expect($(kernelModel.shift)).to.equalMat($(expectedShift));
      expect($(kernelModel.mean)).to.equalMat($(expectedMean));
      expect($(kernelModel.variance)).to.equalMat($(expectedVariance));
    });

    it(@"should deserialize instance normalization", ^{
      auto neuralNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"instnorm.nnmodel"]];
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:neuralNetworkURL error:&error];
      expect(error).to.beNil();

      auto convolutionKernelsSize = model->convolutionKernels.size();
      expect(convolutionKernelsSize).to.equal(0);
      auto poolingKernelsSize = model->poolingKernels.size();
      expect(poolingKernelsSize).to.equal(0);
      auto affineKernelsSize = model->affineKernels.size();
      expect(affineKernelsSize).to.equal(0);
      auto activationKernelsSize = model->activationKernels.size();
      expect(activationKernelsSize).to.equal(0);
      auto normalizationKernelsSize = model->normalizationKernels.size();
      expect(normalizationKernelsSize).to.equal(1);

      cv::Mat1f expectedScale = (cv::Mat1f(1, 3) << 0, 1, 2);
      cv::Mat1f expectedShift = (cv::Mat1f(1, 3) << 3, 4, 5);

      std::string layerName = "instance";
      pnk::NormalizationKernelModel kernelModel = model->normalizationKernels[layerName];
      expect(kernelModel.inputFeatureChannels).to.equal(3);
      expect(kernelModel.computeMeanVar).to.beTruthy();
      expect(kernelModel.instanceNormalization).to.beTruthy();
      expect(kernelModel.epsilon).to.equal(0.00001);
      expect($(kernelModel.scale)).to.equalMat($(expectedScale));
      expect($(kernelModel.shift)).to.equalMat($(expectedShift));
    });
  });

  context(@"style transfer model", ^{
    __block NSURL *styleTransferNetworkURL;

    beforeEach(^{
      styleTransferNetworkURL =
          [NSURL URLWithString:[NSBundle.lt_testBundle lt_pathForResource:@"sst_lilien.nnmodel"]];
    });

    it(@"should deserialize", ^{
      NSError *error;
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:styleTransferNetworkURL
                                                             error:&error];
      expect(error).to.beNil();
    });

    it(@"should deserialize with correct layers", ^{
      auto model = [neuralNetworkModelFactory modelWithCoreMLModel:styleTransferNetworkURL
                                                             error:nil];

      expect(model->convolutionKernels.size()).to.equal(16);
      expect(model->poolingKernels.size()).to.equal(0);
      expect(model->affineKernels.size()).to.equal(0);
      expect(model->activationKernels.size()).to.equal(11);
      expect(model->normalizationKernels.size()).to.equal(17);
      expect(model->networkMetadata.size()).to.equal(0);
    });
  });
});

SpecEnd
