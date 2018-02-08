// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleTransferNetwork.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

#import "PNKNeuralNetworkModel.h"
#import "PNKNeuralNetworkModelFactory.h"

DeviceSpecBegin(PNKStyleTransferNetwork)

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKStyleTransferNetwork *network;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"stylize", ^{
  it(@"should stylize color image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto modelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"echo.nnmodel"]];
    auto model = [[[PNKNeuralNetworkModelFactory alloc] init] modelWithCoreMLModel:modelURL
                                                                             error:&error];

    network = [[PNKStyleTransferNetwork alloc] initWithDevice:device model:*model];

    cv::Mat4b inputMat = LTLoadMat([self class], @"Lena.png");
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                    height:inputMat.rows
                                                  channels:network.outputChannels];

    [network encodeWithCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage
                          styleIndex:55];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    cv::Mat4b expectedMat = LTLoadMat([self class], @"Lena_echo55.png");
    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat outputRGB;
    cv::cvtColor(outputMat, outputRGB, CV_RGBA2RGB);
    cv::Mat outputRGBA;
    cv::cvtColor(outputRGB, outputRGBA, CV_RGB2RGBA);
    expect($(outputRGBA)).to.equalMat($(expectedMat));
  });

  it(@"should stylize grey image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto modelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"sketch.nnmodel"]];
    auto model = [[[PNKNeuralNetworkModelFactory alloc] init] modelWithCoreMLModel:modelURL
                                                                             error:&error];

    network = [[PNKStyleTransferNetwork alloc] initWithDevice:device model:*model];

    cv::Mat4b rgbMat = LTLoadMat([self class], @"Lena.png");
    cv::Mat1b inputMat;
    cv::cvtColor(rgbMat, inputMat, CV_RGBA2GRAY);
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                    height:inputMat.rows
                                                  channels:network.outputChannels];

    [network encodeWithCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage
                          styleIndex:1];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    cv::Mat1b expectedMat = LTLoadMat([self class], @"Lena_sketch1.png");
    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);
    expect($(outputMat)).to.equalMat($(expectedMat));
  });
});

SpecEnd
