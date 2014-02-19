// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTConvolutionProcessor.h"

#import "LTFFTProcessor.h"
#import "LTOpenCVExtensions.h"

@interface LTFFTConvolutionProcessor () {
  cv::Mat1f _first;
  cv::Mat1f _second;
  cv::Mat1f *_output;
}

@property (strong, nonatomic) LTFFTProcessor *firstProcessor;
@property (strong, nonatomic) LTFFTProcessor *secondProcessor;

@property (nonatomic) LTSplitComplexMat firstOutput;
@property (nonatomic) LTSplitComplexMat secondOutput;

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
    _second.addref();
    _output = output;
    self.shiftResult = YES;
    [self createProcessors];
  }
  return self;
}

- (void)dealloc {
  _second.release();
}

- (void)createProcessors {
  self.firstProcessor = [[LTFFTProcessor alloc] initWithRealInput:_first output:&_firstOutput];
  self.secondProcessor = [[LTFFTProcessor alloc] initWithRealInput:_second output:&_secondOutput];
}

- (id<LTImageProcessorOutput>)process {
  [self.firstProcessor process];
  [self.secondProcessor process];

  cv::Mat1f real(_first.size());
  cv::Mat1f imag(_second.size());

  // Multiply two complex matrices. First output is a + i*b, second is c + i*d.
  // TODO: (yaron) test the performance of this loop and optimize using NEON or GPU if needed.
  for (int y = 0; y < _first.rows; ++y) {
    for (int x = 0; x < _first.cols; ++x) {
      float a = self.firstOutput.real(y, x);
      float b = self.firstOutput.imag(y, x);
      float c = self.secondOutput.real(y, x);
      float d = self.secondOutput.imag(y, x);

      real(y, x) = a * c - b * d;
      imag(y, x) = a * d + b * c;
    }
  }

  LTSplitComplexMat output = {.real = *_output, .imag = cv::Mat1f()};
  LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithInput:{.real = real, .imag = imag}
                                                             output:&output];
  processor.normalization = LTFFTTransformNormalizeReal;
  processor.transformDirection = LTFFTTransformDirectionInverse;
  [processor process];

  if (self.shiftResult) {
    LTInPlaceFFTShift(_output);
  }

  return [[LTSingleMatOutput alloc] initWithMat:*_output];
}

#pragma mark -
#pragma mark Model values
#pragma mark -

- (void)setObject:(id __unused)obj forKeyedSubscript:(NSString __unused *)key {
}

- (id)objectForKeyedSubscript:(NSString __unused *)key {
  return nil;
}

@end
