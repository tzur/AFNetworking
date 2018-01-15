// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSkySegmentationNetwork.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

#import "PNKNeuralNetworkModel.h"
#import "PNKNeuralNetworkModelFactory.h"
#import "PNKTensorSerializationUtilities.h"

DeviceSpecBegin(PNKSkySegmentationNetwork)

static const NSUInteger kInputFeatureChannels = 3;

__block id<MTLDevice> device;
__block id<MTLCommandQueue> commandQueue;
__block PNKSkySegmentationNetwork *network;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  commandQueue = [device newCommandQueue];
});

context(@"segment", ^{
  __block cv::Mat expectedMask;
  __block MPSImage *inputImage;
  __block MPSImage *outputImage;

  beforeEach(^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto networkModelURL =
        [NSURL URLWithString:[bundle lt_pathForResource:@"PNKSkySegmentation.nnmodel"]];
    auto networkModel =
        [[[PNKNeuralNetworkModelFactory alloc] init] modelWithCoreMLModel:networkModelURL
                                                                    error:&error];
    auto shapeModelURL =
        [NSURL URLWithString:[bundle lt_pathForResource:@"PNKSkyShape512.model"]];

    auto shapeModel = pnk::loadHalfTensor(shapeModelURL, {512, 512, 1}, &error);

    network = [[PNKSkySegmentationNetwork alloc] initWithDevice:device networkModel:*networkModel
                                                     shapeModel:shapeModel];

    expectedMask = LTLoadMat([self class], @"Bicycles_skymask512.png");

    cv::Mat inputMat = LTLoadMat([self class], @"Bicycles1200.jpg");
    CGSize optimalSize =
        [network optimalInputSizeWithSize:CGSizeMake(inputMat.rows, inputMat.cols)];
    cv::Mat resizedMat;
    cv::resize(inputMat, resizedMat, cv::Size(optimalSize.height, optimalSize.width));

    inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:resizedMat.cols
                                              height:resizedMat.rows
                                            channels:kInputFeatureChannels];
    PNKCopyMatToMTLTexture(inputImage.texture, resizedMat);

    outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputImage.width
                                               height:inputImage.height channels:2];
  });

  it(@"should segment sky image correctly using encode API", ^{
    auto buffer = [commandQueue commandBuffer];
    [network encodeWithCommandBuffer:buffer inputImage:inputImage outputImage:outputImage];
    [buffer commit];
    [buffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);
    std::vector<cv::Mat> channels;
    cv::split(outputMat, channels);

    expect($(channels[0])).to.beCloseToMatWithin($(expectedMask), 3);
  });

  it(@"should segment sky image correctly using async commit API", ^{
    waitUntil(^(DoneCallback done) {
      [network encodeAndCommitAsyncWithCommandQueue:commandQueue inputImage:inputImage
                                        outputImage:outputImage completion:^{
                                          done();
                                        }];
    });

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);
    std::vector<cv::Mat> channels;
    cv::split(outputMat, channels);

    expect($(channels[0])).to.beCloseToMatWithin($(expectedMask), 3);
  });
});

SpecEnd
