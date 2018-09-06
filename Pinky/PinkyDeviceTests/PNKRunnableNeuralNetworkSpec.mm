// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKRunnableNeuralNetwork.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

#import "PNKNetworkSchemeFactory.h"

DeviceSpecBegin(PNKRunnableNeuralNetwork)

it(@"should run the network successfully", ^{
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  id<MTLCommandQueue> commandQueue = [device newCommandQueue];

  NSBundle *bundle = NSBundle.lt_testBundle;
  NSError *error;
  auto networkModelURL =
      [NSURL URLWithString:[bundle lt_pathForResource:@"person.nnmodel"]];

  auto scheme = [PNKNetworkSchemeFactory schemeWithDevice:device coreMLModel:networkModelURL
                                                            error:&error];
  expect((bool)scheme).to.beTruthy();

  auto network = [[PNKRunnableNeuralNetwork alloc] initWithNetworkScheme:*scheme];
  NSString *inputImageName = network.inputImageNames[0];
  NSString *outputImageName = network.outputImageNames[0];

  auto expectedMask = LTLoadMat([self class], @"person_mask.png");

  auto inputMat = LTLoadMat([self class], @"person.png");

  MTLSize inputSize = {(NSUInteger)inputMat.cols, (NSUInteger)inputMat.rows, 3};
  auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device size:inputSize];
  PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

  auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width
                                                  height:inputImage.height channels:2];

  auto buffer = [commandQueue commandBuffer];
  [network encodeWithCommandBuffer:buffer
                       inputImages:@{inputImageName: inputImage}
                      outputImages:@{outputImageName: outputImage}];
  [buffer commit];
  [buffer waitUntilCompleted];

  auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

  std::vector<cv::Mat> channels;
  cv::split(outputMat, channels);

  expect($(channels[0])).to.beCloseToMatWithin($(expectedMask), 8);
});

DeviceSpecEnd
