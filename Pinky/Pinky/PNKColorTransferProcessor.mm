// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferProcessor.h"

#import <LTEngine/LT3DLUT.h>
#import <LTEngine/LTColorTransferProcessor+OptimalRotations.h>

#import "PNKAvailability.h"
#import "PNKColorTransferCDF.h"
#import "PNKColorTransferHistogram.h"
#import "PNKColorTransferHistogramSpecification.h"
#import "PNKColorTransferMinAndMax.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKPixelBufferUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Array of single-precision floats.
typedef std::vector<float> Floats;

@interface PNKColorTransferProcessor ()

/// Device to encode kernel operations.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Compiled state of kernel that converts an \c MTLTexture into floats \c MTLBuffer.
@property (readonly, nonatomic) id<MTLComputePipelineState> convertToBufferState;

/// Compiled state of kernel that copies a lattice buffer from one buffer to another.
@property (readonly, nonatomic) id<MTLComputePipelineState> cloneLatticeState;

/// Computes global min and max pixel values per channel in both input and reference buffers.
@property (readonly, nonatomic) PNKColorTransferMinAndMax *findMinMax;

/// Computes the histogram per channel on the input buffer.
@property (strong, nonatomic) PNKColorTransferHistogram *computeHistogramInput;

/// Computes the histogram per channel on the reference buffer.
@property (strong, nonatomic) PNKColorTransferHistogram *computeHistogramReference;

/// Computes the CDF of the input and inverse CDF of the reference.
@property (strong, nonatomic) PNKColorTransferCDF *computeCDF;

/// Performs histogram specification operation on the input buffer and lattice buffer.
@property (strong, nonatomic) PNKColorTransferHistogramSpecification *specifyHistogram;

/// Input pixels at the current iteration of the color transfer.
@property (readonly, nonatomic) id<MTLBuffer> inputBuffer;

/// Rreference pixels.
@property (readonly, nonatomic) id<MTLBuffer> referenceBuffer;

/// The identity lattice used as starting point for each processing.
@property (readonly, nonatomic) id<MTLBuffer> identityLatticeBuffer;

/// Lattice at the current iteration of the color transfer (GPU-only).
@property (readonly, nonatomic) id<MTLBuffer> currentLatticeBuffer;

/// Lattice after the final iteration of the color transfer (CPU-readable).
@property (readonly, nonatomic) id<MTLBuffer> resultLatticeBuffer;

/// Minimum pixel value (per channel) of both input and reference after changing basis to the basis
/// of the current iteration.
@property (readonly, nonatomic) id<MTLBuffer> minValueBuffer;

/// Maximum pixel value (per channel) of both input and reference after changing basis to the basis
/// of the current iteration.
@property (readonly, nonatomic) id<MTLBuffer> maxValueBuffer;

/// Array of buffers with \c 3x3 change of basis transformations, for every iteration of the color
/// transfer.
@property (readonly, nonatomic) NSArray<id<MTLBuffer>> *transformBuffers;

/// Histogram of the input in the basis of the current iteration.
@property (strong, nonatomic) id<MTLBuffer> inputHistogramBuffer;

/// Histogram of the reference in the basis of the current iteration.
@property (strong, nonatomic) id<MTLBuffer> referenceHistogramBuffer;

/// Array of buffers with the per-channel CDF of the input in the basis of the current iteration.
@property (strong, nonatomic) NSArray<id<MTLBuffer>> *inputCDFBuffers;

/// Array of buffers with the per-channel inverse CDF of the reference in the basis of the current
/// iteration.
@property (strong, nonatomic) NSArray<id<MTLBuffer>> *referenceInverseCDFBuffers;

@end

@implementation PNKColorTransferProcessor

/// Recommended number of pixels for both \c input and \reference for optimal combination of
/// results quality and running time.
static const NSUInteger kRecommendedPixelCount = 500 * 500;

/// Size of the 3D lookup table lattice.
static const NSUInteger kLatticeGridSize = 16;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (nullable instancetype)initWithInputSize:(CGSize)inputSize referenceSize:(CGSize)referenceSize {
  LTParameterAssert(std::min(inputSize) > 0, @"Invalid input size (%@): must be positive",
                    NSStringFromCGSize(inputSize));
  LTParameterAssert(std::min(referenceSize) > 0, @"Invalid reference size (%@): must be positive",
                    NSStringFromCGSize(referenceSize));

  if (self = [super init]) {
    _device = PNKDefaultDevice();
    if (!PNKSupportsMTLDevice(self.device)) {
      return nil;
    }

    _inputSize = inputSize;
    _referenceSize = referenceSize;
    [self createBuffers];
    [self createComputeComponents];
  }

  return self;
}

#pragma mark -
#pragma mark Buffers
#pragma mark -

- (void)createBuffers {
  [self createInputAndReferenceBuffers];
  [self createMinMaxValueBuffers];
  [self createLatticeBuffers];
  [self createTransformBuffers];
  [self updateBuffersIfNeeded];
}

- (void)createInputAndReferenceBuffers {
  _inputBuffer = [self privateBufferWithLength:self.inputPixels * 4 * sizeof(float)];
  _referenceBuffer = [self privateBufferWithLength:self.referencePixels * 4 * sizeof(float)];
}

- (void)createMinMaxValueBuffers {
  _minValueBuffer = [self privateBufferWithLength:4 * sizeof(float)];
  _maxValueBuffer = [self privateBufferWithLength:4 * sizeof(float)];
}

- (void)createLatticeBuffers {
  _identityLatticeBuffer = [self sharedBufferFromLattice:[self identityLattice]];
  _currentLatticeBuffer = [self privateBufferWithLength:self.identityLatticeBuffer.length];
  _resultLatticeBuffer = [self.device newBufferWithLength:self.identityLatticeBuffer.length
                                                  options:MTLResourceCPUCacheModeDefaultCache |
                                                          MTLResourceStorageModeShared];
}

- (const cv::Mat3f)identityLattice {
  static cv::Mat3f lattice;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
    lattice.create(3, latticeDims);
    for (int b = 0; b < (int)kLatticeGridSize; ++b) {
      for (int g = 0; g < (int)kLatticeGridSize; ++g) {
        for (int r = 0; r < (int)kLatticeGridSize; ++r) {
          cv::Vec3f &rgbColor = lattice(b, g, r);
          rgbColor[0] = ((float)r) / (kLatticeGridSize - 1);
          rgbColor[1] = ((float)g) / (kLatticeGridSize - 1);
          rgbColor[2] = ((float)b) / (kLatticeGridSize - 1);
        }
      }
    }
  });

  return lattice.clone();
}

- (id<MTLBuffer>)sharedBufferFromLattice:(const cv::Mat3f &)lattice {
  auto buffer = [self.device newBufferWithLength:self.latticeElements * 4 * sizeof(float)
                                         options:MTLResourceOptionCPUCacheModeWriteCombined |
                                                 MTLResourceStorageModeShared];

  for (NSUInteger i = 0; i < lattice.total(); ++i) {
    auto v = *(lattice.begin() + i);
    for (NSUInteger d = 0; d < 4; ++d) {
      ((float *)buffer.contents)[i * 4 + d] = d < 3 ? v[(int)d] : 0;
    }
  }

  return buffer;
}

- (void)createTransformBuffers {
  auto processor = [[LTColorTransferProcessor alloc] init];
  auto rotations = processor.optimalRotations;

  NSMutableArray<id<MTLBuffer>> *transformBuffers = [NSMutableArray array];
  for (auto mat : rotations) {
    auto transformBuffer = [self.device newBufferWithLength:12 * sizeof(float)
                                                    options:MTLResourceCPUCacheModeWriteCombined |
                                                            MTLResourceStorageModeShared];

    cv::Mat1f transformBufferMat(3, 4, (float *)transformBuffer.contents);
    cv::transpose(mat, transformBufferMat(cv::Rect(0, 0, 3, 3)));

    [transformBuffers addObject:transformBuffer];
  }

  _transformBuffers = transformBuffers;
}

- (void)updateBuffersIfNeeded {
  NSUInteger histogramBuffersLength = self.histogramBins * 4 * sizeof(uint);
  if (histogramBuffersLength != self.inputHistogramBuffer.length) {
    self.inputHistogramBuffer = [self privateBufferWithLength:histogramBuffersLength];
    self.referenceHistogramBuffer = [self privateBufferWithLength:histogramBuffersLength];
  }

  auto cdfBuffersLength = self.histogramBins * sizeof(float);
  if (cdfBuffersLength != self.inputCDFBuffers.firstObject.length) {
    self.inputCDFBuffers = @[
      [self privateBufferWithLength:cdfBuffersLength],
      [self privateBufferWithLength:cdfBuffersLength],
      [self privateBufferWithLength:cdfBuffersLength]
    ];

    self.referenceInverseCDFBuffers = @[
      [self privateBufferWithLength:cdfBuffersLength * PNKColorTransferCDF.inverseCDFScaleFactor],
      [self privateBufferWithLength:cdfBuffersLength * PNKColorTransferCDF.inverseCDFScaleFactor],
      [self privateBufferWithLength:cdfBuffersLength * PNKColorTransferCDF.inverseCDFScaleFactor]
    ];
  }
}

- (id<MTLBuffer>)privateBufferWithLength:(NSUInteger)length {
  return [self.device newBufferWithLength:length options:MTLResourceStorageModePrivate];
}

#pragma mark -
#pragma mark Compute States
#pragma mark -

- (void)createComputeComponents {
  [self createComputeStates];

  _findMinMax = [[PNKColorTransferMinAndMax alloc]
                 initWithDevice:self.device
                 inputSizes:@[@(self.inputSize), @(self.referenceSize)]];

  [self updateComputeComponentsIfNeeded];
}

- (void)createComputeStates {
  _convertToBufferState = PNKCreateComputeState(self.device, @"convertByteToFloat");
  _cloneLatticeState = PNKCreateComputeState(self.device, @"cloneLattice");
}

- (void)updateComputeComponentsIfNeeded {
  if (self.computeHistogramInput.histogramBins != self.histogramBins) {
    self.computeHistogramInput = [[PNKColorTransferHistogram alloc]
                                  initWithDevice:self.device histogramBins:self.histogramBins
                                  inputSize:self.inputPixels];
  }

  if (self.computeHistogramReference.histogramBins != self.histogramBins) {
    self.computeHistogramReference = [[PNKColorTransferHistogram alloc]
                                      initWithDevice:self.device histogramBins:self.histogramBins
                                      inputSize:self.referencePixels];
  }

  if (self.computeCDF.histogramBins != self.histogramBins) {
    self.computeCDF = [[PNKColorTransferCDF alloc]
                       initWithDevice:self.device histogramBins:self.histogramBins];
  }

  if (self.specifyHistogram.histogramBins != self.histogramBins ||
      self.specifyHistogram.dampingFactor != self.dampingFactor) {
    self.specifyHistogram = [[PNKColorTransferHistogramSpecification alloc]
                             initWithDevice:self.device histogramBins:self.histogramBins
                             dampingFactor:self.dampingFactor];
  }
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (nullable LT3DLUT *)lutForInput:(CVPixelBufferRef)input reference:(CVPixelBufferRef)reference {
  [self verifyPixelBufferFormat:input];
  [self verifyPixelBufferFormat:reference];

  auto inputSize = [self sizeForPixelBuffer:input];
  auto referenceSize = [self sizeForPixelBuffer:reference];
  LTParameterAssert(inputSize == self.inputSize, @"Invalid input size (%@): expected %@",
                    NSStringFromCGSize(inputSize), NSStringFromCGSize(self.inputSize));
  LTParameterAssert(referenceSize == self.referenceSize,
                    @"Invalid reference size (%@): expected %@",
                    NSStringFromCGSize(referenceSize), NSStringFromCGSize(self.referenceSize));

  return [self lutForInputMetalImage:PNKImageFromPixelBuffer(input, self.device)
                 referenceMetalImage:PNKImageFromPixelBuffer(reference, self.device)];
}

- (void)verifyPixelBufferFormat:(CVPixelBufferRef)pixelBuffer {
  OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
  LTParameterAssert(format == kCVPixelFormatType_32BGRA || format == kCVPixelFormatType_64RGBAHalf,
                    @"Invalid pixel buffer format (%u): must be RGBA", (unsigned int)format);
}

- (CGSize)sizeForPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  return CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
}

- (nullable LT3DLUT *)lutForInputMetalImage:(MPSImage *)input
                        referenceMetalImage:(MPSImage *)reference {
  [self updateBuffersIfNeeded];
  [self updateComputeComponentsIfNeeded];

  auto commandQueue = PNKDefaultCommandQueue();
  auto commandBuffer = [commandQueue commandBuffer];

  [self prepareBuffersWithCommandBuffer:commandBuffer input:input reference:reference];

  for (NSUInteger i = 0; i < self.iterations; ++i) {
    [self performIterationWithCommandBuffer:commandBuffer transformBuffer:self.transformBuffers[i]
                             minValueBuffer:self.minValueBuffer maxValueBuffer:self.maxValueBuffer];
  }

  PNKComputeDispatchWithDefaultThreads(self.cloneLatticeState, commandBuffer,
                                       @[self.currentLatticeBuffer, self.resultLatticeBuffer],
                                       @"copyLattice: identity", self.latticeElements);

  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];

  if (commandBuffer.status == MTLCommandBufferStatusError) {
    LogError(@"Failed to create color transfer lookup table: %@", commandBuffer.error);
    return nil;
  }

  return [self lutFromBuffer:self.resultLatticeBuffer];
}

- (void)prepareBuffersWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                  input:(MPSImage *)input reference:(MPSImage *)reference {
  PNKComputeDispatchWithDefaultThreads(self.convertToBufferState, commandBuffer,
                                       @[self.inputBuffer], @[input], @[],
                                       @"convertByteToFloat: input",
                                       {input.width, input.height, 1});
  PNKComputeDispatchWithDefaultThreads(self.convertToBufferState, commandBuffer,
                                       @[self.referenceBuffer], @[reference], @[],
                                       @"convertByteToFloat: reference",
                                       {reference.width, reference.height, 1});
  PNKComputeDispatchWithDefaultThreads(self.cloneLatticeState, commandBuffer,
                                       @[self.identityLatticeBuffer, self.currentLatticeBuffer],
                                       @"copyLattice: identity", self.latticeElements);
}

- (void)performIterationWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                          transformBuffer:(id<MTLBuffer>)transformBuffer
                           minValueBuffer:(id<MTLBuffer>)minValueBuffer
                           maxValueBuffer:(id<MTLBuffer>)maxValueBuffer {
  [self.findMinMax
   encodeToCommandBuffer:commandBuffer inputBuffers:@[self.inputBuffer, self.referenceBuffer]
   transformBuffer:transformBuffer minValueBuffer:minValueBuffer maxValueBuffer:maxValueBuffer];

  [self.computeHistogramInput
   encodeToCommandBuffer:commandBuffer inputBuffer:self.inputBuffer
   transformBuffer:transformBuffer minValueBuffer:minValueBuffer maxValueBuffer:maxValueBuffer
   histogramBuffer:self.inputHistogramBuffer];

  [self.computeHistogramReference
   encodeToCommandBuffer:commandBuffer inputBuffer:self.referenceBuffer
   transformBuffer:transformBuffer minValueBuffer:minValueBuffer maxValueBuffer:maxValueBuffer
   histogramBuffer:self.referenceHistogramBuffer];

  [self.computeCDF
   encodeToCommandBuffer:commandBuffer inputHistogramBuffer:self.inputHistogramBuffer
   referenceHistogramBuffer:self.referenceHistogramBuffer minValueBuffer:minValueBuffer
   maxValueBuffer:maxValueBuffer cdfBuffers:self.inputCDFBuffers
   inverseCDFBuffers:self.referenceInverseCDFBuffers];

  [self.specifyHistogram
   encodeToCommandBuffer:commandBuffer dataBuffer:self.inputBuffer transformBuffer:transformBuffer
   minValueBuffer:minValueBuffer maxValueBuffer:maxValueBuffer
   inputCDFBuffers:self.inputCDFBuffers referenceInverseCDFBuffers:self.referenceInverseCDFBuffers];

  [self.specifyHistogram
   encodeToCommandBuffer:commandBuffer dataBuffer:self.currentLatticeBuffer
   transformBuffer:transformBuffer minValueBuffer:minValueBuffer maxValueBuffer:maxValueBuffer
   inputCDFBuffers:self.inputCDFBuffers referenceInverseCDFBuffers:self.referenceInverseCDFBuffers];
}

- (LT3DLUT *)lutFromBuffer:(id<MTLBuffer>)buffer {
  auto lattice = [self latticeFromBuffer:buffer];
  auto byteLattice = [self byteLatticeFromFloatLattice:lattice];
  return [[LT3DLUT alloc] initWithLatticeMat:byteLattice];
}

- (cv::Mat3f)latticeFromBuffer:(id<MTLBuffer>)buffer {
  int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
  cv::Mat3f lattice(3, latticeDims);
  for (NSUInteger i = 0; i < self.latticeElements; ++i) {
    cv::Vec3f v;
    for (NSUInteger d = 0; d < 3; ++d) {
      v[(int)d] = ((float *)buffer.contents)[i * 4 + (int)d];
    }
    *(lattice.begin() + i) = v;
  }

  return lattice;
}

- (cv::Mat4b)byteLatticeFromFloatLattice:(const cv::Mat3f &)lattice {
  int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
  cv::Mat4b byteLattice(3, latticeDims);
  std::transform(lattice.begin(), lattice.end(), byteLattice.begin(), [](const cv::Vec3f &v) {
    return (cv::Vec4b)std::clamp(LTVector4(v[0], v[1], v[2], 1), 0, 1);
  });
  return byteLattice;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(NSUInteger, iterations, Iterations, 1, 50, 20);
LTProperty(NSUInteger, histogramBins, HistogramBins, 2, 256, 32);
LTProperty(float, dampingFactor, DampingFactor, 0, 1, 0.2);

+ (NSUInteger)recommendedNumberOfPixels {
  return kRecommendedPixelCount;
}

- (NSUInteger)latticeElements {
  return kLatticeGridSize * kLatticeGridSize * kLatticeGridSize;
}

- (NSUInteger)inputPixels {
  return self.inputSize.width * self.inputSize.height;
}

- (NSUInteger)referencePixels {
  return self.referenceSize.width * self.referenceSize.height;
}

@end

#else

@implementation PNKColorTransferProcessor

- (nullable instancetype)initWithInputSize:(__unused CGSize)inputSize
                             referenceSize:(__unused CGSize)referenceSize {
  return nil;
}

- (nullable LT3DLUT *)lutForInput:(__unused CVPixelBufferRef)input
                        reference:(__unused CVPixelBufferRef)reference {
  return nil;
}

+ (NSUInteger)recommendedNumberOfPixels {
  return 0;
}

LTProperty(NSUInteger, iterations, Iterations, 1, 50, 20);
LTProperty(NSUInteger, histogramBins, HistogramBins, 2, 256, 32);
LTProperty(float, dampingFactor, DampingFactor, 0, 1, 0.2);

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
