// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTSplitComplexMat.h"

@interface LTFFTProcessor ()

@property (nonatomic) LTSplitComplexMat *input;
@property (nonatomic) LTSplitComplexMat *output;

@property (readonly, nonatomic) cv::Size size;
@property (readonly, nonatomic) size_t totalElements;

@end

@implementation LTFFTProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRealInput:(const cv::Mat1f &)realInput output:(LTSplitComplexMat *)output {
  LTSplitComplexMat *input = [[LTSplitComplexMat alloc]
                              initWithReal:realInput imag:cv::Mat1f::zeros(realInput.size())];
  return [self initWithInput:input output:output];
}

- (instancetype)initWithInput:(LTSplitComplexMat *)input output:(LTSplitComplexMat *)output {
  if (self = [super init]) {
    LTParameterAssert([self isPowerOfTwo:input.real.size()] &&
                      [self isPowerOfTwo:input.imag.size()],
                      @"Both input dimensions must be a power of two");
    LTParameterAssert(input.real.size == input.imag.size, @"Real and imaginary input matrices "
                      "should be of the same size");

    self.input = input;
    self.output = output;

    self.normalization = LTFFTTransformNormalizeReal | LTFFTTransformNormalizeImag;
  }
  return self;
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
#pragma mark FFT Setup
#pragma mark -

+ (FFTSetup)fftSetupForSize:(cv::Size)size {
  static FFTSetup setup = NULL;
  static int maximalSetupDimension = 0;

  // Create a new setup only if the requested dimension is larger than the one in the current setup.
  int maximalDimension = std::max(size.width, size.height);
  LTAssert(maximalDimension > 0, @"Requested maximal dimension for setup must be larger than 0");

  if (maximalDimension > maximalSetupDimension) {
    if (setup) {
      vDSP_destroy_fftsetup(setup);
    }
    setup = vDSP_create_fftsetup(log2(maximalDimension), kFFTRadix2);
    maximalSetupDimension = maximalDimension;
  }
  return setup;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (id<LTImageProcessorOutput>)process {
  _output.real.create(self.size);
  _output.imag.create(self.size);

  [self runFFT];

  return [[LTSplitComplexMatOutput alloc] initWithSplitComplexMat:self.output];
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
  output.realp = (float *)_output.real.data;
  output.imagp = (float *)_output.imag.data;

  const vDSP_Stride kRowStride = 1;
  const vDSP_Stride kColumnStride = 0;

  FFTSetup fftSetup = [[self class] fftSetupForSize:self.size];

  if (self.transformDirection == LTFFTTransformDirectionForward) {
    vDSP_fft2d_zop(fftSetup, &input, kRowStride, kColumnStride, &output,
                   kRowStride, kColumnStride, logColumns, logRows, FFT_FORWARD);
  } else {
    vDSP_fft2d_zop(fftSetup, &input, kRowStride, kColumnStride, &output,
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

@end
