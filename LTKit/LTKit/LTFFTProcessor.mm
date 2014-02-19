// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTProcessor.h"

#import <Accelerate/Accelerate.h>

@interface LTSplitComplexOutput ()
@property (readwrite, nonatomic) LTSplitComplexMat splitComplexMat;
@end

@implementation LTSplitComplexOutput

- (instancetype)initWithSplitComplexMat:(LTSplitComplexMat)splitComplexMat {
  if (self = [super init]) {
    self.splitComplexMat = splitComplexMat;
  }
  return self;
}

@end

@interface LTFFTProcessor ()

@property (nonatomic) LTSplitComplexMat input;
@property (nonatomic) LTSplitComplexMat *output;

@property (nonatomic) FFTSetup fftSetup;

@property (readonly, nonatomic) cv::Size size;
@property (readonly, nonatomic) size_t totalElements;

@end

@implementation LTFFTProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRealInput:(const cv::Mat1f &)realInput output:(LTSplitComplexMat *)output {
  LTSplitComplexMat input = {.real = realInput, .imag = cv::Mat1f::zeros(realInput.size())};
  return [self initWithInput:input output:output];
}

- (instancetype)initWithInput:(LTSplitComplexMat)input output:(LTSplitComplexMat *)output {
  if (self = [super init]) {
    LTParameterAssert([self isPowerOfTwo:input.real.size()] &&
                      [self isPowerOfTwo:input.imag.size()],
                      @"Both input dimensions must be a power of two");
    LTParameterAssert(input.real.size == input.imag.size, @"Real and imaginary input matrices "
                      "should be of the same size");

    self.input = input;
    self.output = output;
    _output->real.addref();
    _output->imag.addref();

    self.normalization = LTFFTTransformNormalizeReal | LTFFTTransformNormalizeImag;
  }
  return self;
}

- (void)dealloc {
  if (!_fftSetup) {
    vDSP_destroy_fftsetup(_fftSetup);
    _fftSetup = nil;
  }
  if (_output) {
    _output->real.release();
    _output->imag.release();
  }
}

- (BOOL)isPowerOfTwo:(cv::Size)size {
  int width = size.width;
  int height = size.height;

  return !((width & (width - 1)) || (height & (height - 1)));
}

#pragma mark -
#pragma mark Input model
#pragma mark -

- (void)setObject:(id __unused)obj forKeyedSubscript:(NSString __unused *)key {
}

- (id)objectForKeyedSubscript:(NSString __unused *)key {
  return nil;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (id<LTImageProcessorOutput>)process {
  _output->real.create(self.size);
  _output->imag.create(self.size);

  [self runFFT];

  return [[LTSplitComplexOutput alloc] initWithSplitComplexMat:*self.output];
}

- (cv::Size)size {
  return self.input.real.size();
}

- (size_t)totalElements {
  return self.input.real.total();
}

- (void)runFFT {
  vDSP_Length totalElements = log2(self.totalElements);
  vDSP_Length logRows = totalElements / 2;
  vDSP_Length logColumns = totalElements / 2;
  vDSP_Length numElements = 1 << (logRows + logColumns);

  DSPSplitComplex input;
  input.realp = (float *)_input.real.data;
  input.imagp = (float *)_input.imag.data;

  DSPSplitComplex output;
  output.realp = (float *)_output->real.data;
  output.imagp = (float *)_output->imag.data;

  const vDSP_Stride kRowStride = 1;
  const vDSP_Stride kColumnStride = 0;

  if (self.transformDirection == LTFFTTransformDirectionForward) {
    vDSP_fft2d_zop(self.fftSetup, &input, kRowStride, kColumnStride, &output,
                   kRowStride, kColumnStride, logColumns, logRows, FFT_FORWARD);
  } else {
    vDSP_fft2d_zop(self.fftSetup, &input, kRowStride, kColumnStride, &output,
                   kRowStride, kColumnStride, logColumns, logRows, FFT_INVERSE);

    // Since the inverse transform doesn't scale by 1/N, we need to do it ourselves.
    float scale = 1.0 / numElements;
    if (self.normalization & LTFFTTransformNormalizeReal) {
      vDSP_vsmul(output.realp, 1, &scale, output.realp, 1, numElements);
    }
    if (self.normalization & LTFFTTransformNormalizeImag) {
      vDSP_vsmul(output.imagp, 1, &scale, output.imagp, 1, numElements);
    }
  }
}

- (FFTSetup)fftSetup {
  // TODO:(yaron) initialize this statically, per log2(maximalDimension).
  if (!_fftSetup) {
    int maximalDimension = std::max(self.size.width, self.size.height);
    _fftSetup = vDSP_create_fftsetup(log2(maximalDimension), kFFTRadix2);
  }
  return _fftSetup;
}

@end
