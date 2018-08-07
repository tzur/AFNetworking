// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBComputeDispatch.h"

#import <LTKitTestUtils/NSBundle+Test.h>

#import "MPSImage+Factory.h"
#import "MPSImage+OpenCV.h"
#import "MPSTemporaryImage+Factory.h"
#import "MTBComputePipelineState.h"

static cv::Mat MTBFillMatrix(int rows, int columns, int channels, int modulo) {
  cv::Mat1b matrix(rows * columns, channels);
  for (int i = 0; i < rows; ++i) {
    for (int j = 0; j < columns; ++j) {
      for (int k = 0; k < channels; ++k) {
        matrix.at<uchar>(i * columns + j, k) = (uchar)((i + j + k) % modulo);
      }
    }
  }
  return matrix.reshape(channels, rows);
}

static id<MTLBuffer> MTBMTLBufferFromMat(const cv::Mat &mat, id<MTLDevice> device) {
  NSUInteger bufferSize = (NSUInteger)mat.total() * mat.elemSize();
  id<MTLBuffer> buffer = [device newBufferWithLength:bufferSize
                                             options:MTLResourceCPUCacheModeWriteCombined];

  void *bufferContents = (ushort *)buffer.contents;
  memcpy(bufferContents, mat.data, bufferSize);

  return buffer;
}

DeviceSpecBegin(MTBComputeDispatch)

__block id<MTLDevice> device;
__block id<MTLLibrary> library;
__block id<MTLCommandBuffer> commandBuffer;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();

  auto bundle = [NSBundle lt_testBundle];
  auto libraryPath = [bundle pathForResource:@"default" ofType:@"metallib"];
  library = [device newLibraryWithFile:libraryPath error:nil];

  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

afterEach(^{
  commandBuffer = nil;
  library = nil;
  device = nil;
});

context(@"compute dispatch with default thread group size", ^{
  context(@"kernel with buffers and images", ^{
    it(@"should provide correct result",  ^{
      cv::Mat1b inputMat = MTBFillMatrix(4, 4, 1, 3);
      auto inputImage = [MPSImage mtb_imageWithDevice:device mat:inputMat];

      auto inputBuffer = [device newBufferWithLength:1
                                             options:MTLResourceCPUCacheModeWriteCombined];
      ((uchar *)inputBuffer.contents)[0] = (uchar)5;

      cv::Mat1b expectedOutputMat = inputMat + (uchar)5;

      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionBufferAndTexture");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer, @[inputBuffer], @[inputImage],
                                           @[outputImage], nil, MTLSizeMake(4, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat1b outputMat = [outputImage mtb_mat];

      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should decrement readCount for input images but not for output images",  ^{
      auto inputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                               width:4 height:4
                                                                            channels:1];
      auto inputBuffer = [device newBufferWithLength:1
                                             options:MTLResourceCPUCacheModeWriteCombined];
      auto outputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                                width:4 height:4
                                                                             channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionBufferAndTexture");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer, @[inputBuffer], @[inputImage],
                                           @[outputImage], nil, MTLSizeMake(4, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      expect(inputImage.readCount).to.equal(0);
      expect(outputImage.readCount).to.equal(1);
    });
  });

  context(@"kernel with buffers", ^{
    it(@"should provide correct result",  ^{
      cv::Mat1b firstInputMat = MTBFillMatrix(32, 1, 1, 3);
      cv::Mat1b secondInputMat = MTBFillMatrix(32, 1, 1, 5);
      cv::Mat1b expectedOutputMat = firstInputMat + secondInputMat;

      auto firstInputBuffer = MTBMTLBufferFromMat(firstInputMat, device);
      auto secondInputBuffer = MTBMTLBufferFromMat(secondInputMat, device);
      auto bufferSize = firstInputBuffer.length;
      auto outputBuffer = [device newBufferWithLength:bufferSize
                                              options:MTLResourceCPUCacheModeWriteCombined];

      auto state = MTBCreateComputePipelineState(library, @"additionBuffer");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer,
                                           @[firstInputBuffer, secondInputBuffer, outputBuffer],
                                           nil, bufferSize / sizeof(uchar));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat outputMat(expectedOutputMat.rows, expectedOutputMat.cols, CV_8UC1,
                        outputBuffer.contents);

      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });
  });

  context(@"kernel with textures", ^{
    it(@"should provide correct result for single-slice images",  ^{
      cv::Mat1b firstInputMat = MTBFillMatrix(4, 4, 1, 3);
      cv::Mat1b secondInputMat = MTBFillMatrix(4, 4, 1, 5);
      cv::Mat1b expectedOutputMat = firstInputMat + secondInputMat;

      auto firstInputImage = [MPSImage mtb_imageWithDevice:device mat:firstInputMat];
      auto secondInputImage = [MPSImage mtb_imageWithDevice:device mat:secondInputMat];
      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionSingle");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer,
                                           @[firstInputImage, secondInputImage], @[outputImage],
                                           nil, MTLSizeMake(4, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat1b outputMat = [outputImage mtb_mat];

      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should provide correct result for multiple-slice images",  ^{
      cv::Mat firstInputMat = MTBFillMatrix(4, 4, 7, 3);
      cv::Mat secondInputMat = MTBFillMatrix(4, 4, 7, 5);
      cv::Mat expectedOutputMat = firstInputMat + secondInputMat;

      auto firstInputImage = [MPSImage mtb_imageWithDevice:device mat:firstInputMat];
      auto secondInputImage = [MPSImage mtb_imageWithDevice:device mat:secondInputMat];
      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:7];

      auto state = MTBCreateComputePipelineState(library, @"additionArray");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer,
                                           @[firstInputImage, secondInputImage], @[outputImage],
                                           nil, MTLSizeMake(4, 4, 2));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat outputMat = [outputImage mtb_mat];
      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should decrement readCount for input images but not for output images",  ^{
      auto firstInputImage =
          [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:4
                                                                height:4 channels:1];
      auto secondInputImage =
          [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:4
                                                                height:4 channels:1];
      auto outputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                                width:4 height:4
                                                                             channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionSingle");

      MTBComputeDispatchWithDefaultThreads(state, commandBuffer,
                                           @[firstInputImage, secondInputImage], @[outputImage],
                                           nil, MTLSizeMake(4, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      expect(firstInputImage.readCount).to.equal(0);
      expect(secondInputImage.readCount).to.equal(0);
      expect(outputImage.readCount).to.equal(1);
    });
  });
});

context(@"compute dispatch with user-provided thread group size", ^{
  context(@"kernel with buffers and images", ^{
    it(@"should provide correct result",  ^{
      cv::Mat1b inputMat = MTBFillMatrix(4, 4, 1, 3);
      auto inputImage = [MPSImage mtb_imageWithDevice:device mat:inputMat];

      auto inputBuffer = [device newBufferWithLength:1
                                             options:MTLResourceCPUCacheModeWriteCombined];
      ((uchar *)inputBuffer.contents)[0] = (uchar)5;

      cv::Mat1b expectedOutputMat = inputMat + (uchar)5;

      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionBufferAndTexture");
      MTBComputeDispatch(state, commandBuffer, @[inputBuffer], @[inputImage], @[outputImage],
                         nil, MTLSizeMake(4, 1, 1), MTLSizeMake(1, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat1b outputMat = [outputImage mtb_mat];

      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should decrement readCount for input images but not for output images",  ^{
      auto inputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                               width:4 height:4
                                                                            channels:1];
      auto inputBuffer = [device newBufferWithLength:1
                                             options:MTLResourceCPUCacheModeWriteCombined];
      auto outputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                                width:4 height:4
                                                                             channels:1];
      auto state = MTBCreateComputePipelineState(library, @"additionBufferAndTexture");

      MTBComputeDispatch(state, commandBuffer, @[inputBuffer], @[inputImage], @[outputImage], nil,
                         MTLSizeMake(4, 1, 1), MTLSizeMake(1, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      expect(inputImage.readCount).to.equal(0);
      expect(outputImage.readCount).to.equal(1);
    });
  });

  context(@"kernel with textures", ^{
    it(@"should provide correct result for single-slice images",  ^{
      cv::Mat1b firstInputMat = MTBFillMatrix(4, 4, 1, 3);
      cv::Mat1b secondInputMat = MTBFillMatrix(4, 4, 1, 5);
      cv::Mat1b expectedOutputMat = firstInputMat + secondInputMat;

      auto firstInputImage = [MPSImage mtb_imageWithDevice:device mat:firstInputMat];
      auto secondInputImage = [MPSImage mtb_imageWithDevice:device mat:secondInputMat];
      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:1];

      auto state = MTBCreateComputePipelineState(library, @"additionSingle");

      MTBComputeDispatch(state, commandBuffer, @[firstInputImage, secondInputImage], @[outputImage],
                         nil, MTLSizeMake(4, 1, 1), MTLSizeMake(1, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      cv::Mat1b outputMat = [outputImage mtb_mat];

      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should provide correct result for multiple-slice images",  ^{
      cv::Mat firstInputMat = MTBFillMatrix(4, 4, 7, 3);
      cv::Mat secondInputMat = MTBFillMatrix(4, 4, 7, 5);
      cv::Mat expectedOutputMat = firstInputMat + secondInputMat;

      auto firstInputImage = [MPSImage mtb_imageWithDevice:device mat:firstInputMat];
      auto secondInputImage = [MPSImage mtb_imageWithDevice:device mat:secondInputMat];
      auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:4 height:4 channels:7];

      auto state = MTBCreateComputePipelineState(library, @"additionArray");

      MTBComputeDispatch(state, commandBuffer, @[firstInputImage, secondInputImage], @[outputImage],
                         nil, MTLSizeMake(4, 1, 2), MTLSizeMake(1, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      auto outputMat = [outputImage mtb_mat];
      expect(cv::countNonZero(outputMat != expectedOutputMat)).to.equal(0);
    });

    it(@"should decrement readCount for input images but not for output images",  ^{
      auto firstInputImage =
          [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:4
                                                                height:4 channels:1];
      cv::Mat1b secondInputMat = MTBFillMatrix(4, 4, 1, 5);
      auto secondInputImage =
          [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:4
                                                                height:4 channels:1];
      auto outputImage = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                                width:4 height:4
                                                                             channels:1];
      auto state = MTBCreateComputePipelineState(library, @"additionSingle");

      MTBComputeDispatch(state, commandBuffer, @[firstInputImage, secondInputImage], @[outputImage],
                         nil, MTLSizeMake(4, 1, 1), MTLSizeMake(1, 4, 1));
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      expect(firstInputImage.readCount).to.equal(0);
      expect(secondInputImage.readCount).to.equal(0);
      expect(outputImage.readCount).to.equal(1);
    });
  });
});

DeviceSpecEnd
