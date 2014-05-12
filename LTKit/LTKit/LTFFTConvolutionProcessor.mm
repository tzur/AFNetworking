// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTConvolutionProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTFFTProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTSplitComplexMat.h"
#import "LTTexture+Factory.h"

@interface LTFFTConvolutionProcessor () {
  cv::Mat1f _first;
  cv::Mat1f _second;
  cv::Mat1f *_output;
}

@property (strong, nonatomic) LTFFTProcessor *firstProcessor;
@property (strong, nonatomic) LTFFTProcessor *secondProcessor;

@property (nonatomic) LTSplitComplexMat *firstOutput;
@property (nonatomic) LTSplitComplexMat *secondOutput;

@end

@implementation LTFFTConvolutionProcessor

- (instancetype)initWithFirstOperand:(const cv::Mat1f &)first
                       secondOperand:(const cv::Mat1f &)second
                              output:(cv::Mat1f *)output {
  LTParameterAssert(output, @"Given output matrix cannot be nil");
  LTParameterAssert(first.size() == second.size() && first.size() == output->size(),
                    @"Both operands and output should have the same size");

  if (self = [super init]) {
    _first = first;
    _second = second;
    _output = output;
    self.shiftResult = YES;
    [self createProcessors];
  }
  return self;
}

- (instancetype)initWithFirstTransformedOperand:(LTSplitComplexMat *)firstTransformed
                                  secondOperand:(const cv::Mat1f &)second
                                         output:(cv::Mat1f *)output {
  LTParameterAssert(output, @"Given output matrix cannot be nil");
  LTParameterAssert(firstTransformed.real.size() == second.size() &&
                    firstTransformed.imag.size() == second.size() &&
                    second.size() == output->size(),
                    @"Both operands and output should have the same size");

  if (self = [super init]) {
    self.firstOutput = firstTransformed;
    _second = second;
    _output = output;
    self.shiftResult = YES;
    [self createProcessors];
  }
  return self;
}

- (void)createProcessors {
  if (!self.firstOutput) {
    self.firstOutput = [[LTSplitComplexMat alloc] init];
    self.firstProcessor = [[LTFFTProcessor alloc] initWithRealInput:_first
                                                             output:self.firstOutput];
  }
  self.secondOutput = [[LTSplitComplexMat alloc] init];
  self.secondProcessor = [[LTFFTProcessor alloc] initWithRealInput:_second
                                                            output:self.secondOutput];
}

- (id<LTImageProcessorOutput>)process {
  [self.firstProcessor process];
  [self.secondProcessor process];

  LTSplitComplexMat *input = [self multiplyTransformedMatrices];
  LTSplitComplexMat *output = [[LTSplitComplexMat alloc] initWithReal:*_output imag:cv::Mat1f()];

  LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithInput:input output:output];
  processor.normalization = LTFFTTransformNormalizeReal;
  processor.transformDirection = LTFFTTransformDirectionInverse;
  [processor process];

  if (self.shiftResult) {
    LTInPlaceFFTShift(_output);
  }

  return [[LTSingleMatOutput alloc] initWithMat:*_output];
}

- (LTSplitComplexMat *)multiplyTransformedMatrices {
  cv::Mat1f real(_second.size());
  cv::Mat1f imag(_second.size());

  DSPSplitComplex first = {
    .realp = (float *)self.firstOutput.real.data,
    .imagp = (float *)self.firstOutput.imag.data
  };
  DSPSplitComplex second = {
    .realp = (float *)self.secondOutput.real.data,
    .imagp = (float *)self.secondOutput.imag.data
  };
  DSPSplitComplex output = {
    .realp = (float *)real.data,
    .imagp = (float *)imag.data
  };
  vDSP_zvmul(&first, 1, &second, 1, &output, 1, _second.total(), 1);

  return [[LTSplitComplexMat alloc] initWithReal:real imag:imag];
}

@end
