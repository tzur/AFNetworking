// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTFFTConvolutionProcessor.h"
#import "LTFFTProcessor.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTPatchBoundaryProcessor.h"
#import "LTPatchKernel.h"
#import "LTQuad.h"
#import "LTQuadCopyProcessor.h"
#import "LTSplitComplexMat.h"
#import "LTTexture+Factory.h"

@interface LTPatchSolverProcessor () {
  /// Single channel float boundary.
  cv::Mat1f _boundarySingleChannel;
  /// This is a duplicated channels version of \c _boundarySingleChannel according to the \c output
  /// channels count.
  cv::Mat _boundaryMultipleChannels;
  /// Boundary convoluted with the kernel.
  cv::Mat1f _paddedChi;
}

/// Mask used to select part of \c sourceQuad to copy.
@property (strong, nonatomic) LTTexture *mask;

/// Threshold between the pixel values considered to be inside the mask and the pixel values
/// considered to be outside the mask when extracting the mask boundary (@see the \c threshold
/// property of \c LTPatchBoundaryProcessor for more information).
@property (readonly, nonatomic) CGFloat maskBoundaryThreshold;

/// Source texture, used to copy the data from.
@property (strong, nonatomic) LTTexture *source;

/// Target texture, used to copy the data to.
@property (strong, nonatomic) LTTexture *target;

/// Solution to the patch PDE.
@property (strong, nonatomic) LTTexture *output;

/// Texture of the resized source to working size.
@property (strong, nonatomic) LTTexture *sourceResized;

/// Texture of the resized target to working size.
@property (strong, nonatomic) LTTexture *targetResized;

/// Texture of the resized mask to working size.
@property (strong, nonatomic) LTTexture *maskResized;

/// Last generation ID of the mask texture that was processed.
@property (nonatomic) id lastProcessedMaskGenerationID;

/// Resizer of source to working size.
@property (strong, nonatomic) LTQuadCopyProcessor *sourceResizer;

/// Resizer of target to working size.
@property (strong, nonatomic) LTQuadCopyProcessor *targetResizer;

/// Resizer of mask to working size.
@property (strong, nonatomic) LTQuadCopyProcessor *maskResizer;

/// FFT result of the padded kernel.
@property (strong, nonatomic) LTSplitComplexMat *paddedTransformedKernel;

/// Size that the patch calculations is done at. Making this size smaller will give a boost in
/// performance, but will yield a less accurate result. Both dimensions must be a power of two.
@property (nonatomic) CGSize workingSize;

@end

@implementation LTPatchSolverProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMask:(LTTexture *)mask source:(LTTexture *)source
                      target:(LTTexture *)target output:(LTTexture *)output {
  return [self initWithMask:mask maskBoundaryThreshold:0 source:source target:target output:output];
}

- (instancetype)initWithMask:(LTTexture *)mask maskBoundaryThreshold:(CGFloat)maskBoundaryThreshold
                      source:(LTTexture *)source target:(LTTexture *)target
                      output:(LTTexture *)output {
  LTParameterAssert(mask.dataType == LTGLPixelDataType8Unorm,
                    @"Mask texture must be of byte precision, got %@", mask.pixelFormat);
  LTParameterAssert(output.dataType == LTGLPixelDataType16Float,
                    @"Output texture must be of half-float precision, got: %@", output.pixelFormat);
  LTParameterAssert(maskBoundaryThreshold >= 0 && maskBoundaryThreshold <= 1,
                    @"maskBoundaryThreshold (%g) must be in [0, 1]", maskBoundaryThreshold);
  LTParameterAssert(source.pixelFormat.channels == target.pixelFormat.channels &&
                    source.pixelFormat.channels == output.pixelFormat.channels,
                    @"Source, target and output must have the same channels count, got %lu, %lu "
                    "and %lu respectively", (unsigned long)source.pixelFormat.channels,
                    (unsigned long)target.pixelFormat.channels,
                    (unsigned long)output.pixelFormat.channels);

  if (self = [super init]) {
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;

    _maskBoundaryThreshold = maskBoundaryThreshold;

    // TODO:(yaron) working dimension can be different than the closest power of two. As discussed
    // in vDSP_create_fftsetup: "Parameter __vDSP_Log2N is a base-two exponent and specifies that
    // the largest transform length that can processed using the resulting setup structure is
    // 2**__vDSP_Log2N (or 3*2**__vDSP_Log2N or 5*2**__vDSP_Log2N if the appropriate flags are
    // passed, as discussed below). That is, the __vDSP_Log2N parameter must equal or exceed the
    // value passed to any subsequent FFT routine using the setup structure returned by this
    // routine.
    CGFloat workingDimension = (1 << (int)ceil(log2(std::max(self.output.size))));
    self.workingSize = CGSizeMake(workingDimension, workingDimension);

    [self createTransformedKernel];
    [self createResizersAndTextures];

    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.sourceQuad = [LTQuad quadFromRect:CGRectFromSize(self.source.size)];
  self.targetQuad = [LTQuad quadFromRect:CGRectFromSize(self.source.size)];
  self.flip = NO;
}

- (void)processMaskIfNeeded {
  if (_paddedChi.empty() || ![self.lastProcessedMaskGenerationID isEqual:self.mask.generationID]) {
    [self createBoundary];
    [self calculateChi];
    self.lastProcessedMaskGenerationID = self.mask.generationID;
  }
}

- (void)flipResizedSourceIfNeeded {
  if (!self.flip) {
    return;
  }
  // TODO:(danny) Implement flipping with GPU support.
  [self.sourceResized mappedImageForWriting:^(cv::Mat * _Nonnull mapped, BOOL) {
    CGSize size = [self maskWorkingRect].size;
    cv::Rect rect = cv::Rect(0, 0, size.width, size.height);
    cv::flip((*mapped)(rect), (*mapped)(rect), 1.0);
  }];
}

- (void)createTransformedKernel {
  cv::Mat1f paddedKernel = LTPatchKernelCreate(self.paddedWorkingSize);

  self.paddedTransformedKernel = [[LTSplitComplexMat alloc] init];
  LTFFTProcessor *processor =
      [[LTFFTProcessor alloc] initWithRealInput:paddedKernel output:self.paddedTransformedKernel];
  [processor process];
}

- (void)createResizersAndTextures {
  self.sourceResized = [LTTexture textureWithSize:self.workingSize
                                      pixelFormat:self.source.pixelFormat allocateMemory:YES];
  self.targetResized = [LTTexture textureWithSize:self.workingSize
                                      pixelFormat:self.target.pixelFormat allocateMemory:YES];
  self.maskResized = [LTTexture byteRGBATextureWithSize:self.workingSize];

  static const LTVector4 kBlack = LTVector4(0, 0, 0, 0);
  [self.sourceResized clearColor:kBlack];
  [self.targetResized clearColor:kBlack];
  [self.maskResized clearColor:kBlack];

  self.sourceResizer = [[LTQuadCopyProcessor alloc] initWithInput:self.source
                                                           output:self.sourceResized];
  self.targetResizer = [[LTQuadCopyProcessor alloc] initWithInput:self.target
                                                           output:self.targetResized];
  self.maskResizer = [[LTQuadCopyProcessor alloc] initWithInput:self.mask
                                                         output:self.maskResized];

  self.sourceResizer.inputQuad = self.sourceQuad;
  self.sourceResizer.outputQuad = [LTQuad quadFromRect:self.maskWorkingRect];
  self.targetResizer.inputQuad = self.targetQuad;
  self.targetResizer.outputQuad = [LTQuad quadFromRect:self.maskWorkingRect];
  self.maskResizer.outputQuad = [LTQuad quadFromRect:self.maskWorkingRect];
}

#pragma mark -
#pragma mark Boundary calculation
#pragma mark -

- (void)createBoundary {
  [self.maskResizer process];

  LTTexture *boundary = [LTTexture byteRedTextureWithSize:self.workingSize];
  LTPatchBoundaryProcessor *processor = [[LTPatchBoundaryProcessor alloc]
                                         initWithInput:self.maskResized output:boundary];
  processor.threshold = self.maskBoundaryThreshold;
  [processor process];

  [boundary mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &self->_boundarySingleChannel, CV_32F);
  }];
  std::vector<cv::Mat1f> channels(self.output.pixelFormat.channels, _boundarySingleChannel);
  cv::merge(channels, _boundaryMultipleChannels);
}

- (void)calculateChi {
  cv::Mat1f paddedBoundarySingle = cv::Mat1f::zeros(self.paddedWorkingSize);
  _boundarySingleChannel.copyTo(paddedBoundarySingle(self.unpaddedRect));

  _paddedChi = [self convolveKernelWith:paddedBoundarySingle];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  if (!self.sourceQuad || !self.targetQuad) {
    return;
  }

  [self processMaskIfNeeded];

  // TODO: (yaron) optional performance boost: process textures that their rect has been changed
  // only.
  [self.sourceResizer process];

  // Flip the source patch if needed, to make sure the membrane will be aligned correctly.
  [self flipResizedSourceIfNeeded];

  [self.targetResizer process];

  // TODO: (yaron) optional performance boost is to move all GPU operations in this processor to CPU
  // for small working sizes. This will avoid the 3-4ms of GPU->CPU synchronization that is occurred
  // when mapping the images for reading.
  __block cv::Mat source, target;
  [self.sourceResized mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &source, CV_32FC(mapped.channels()));
  }];
  [self.targetResized mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &target, CV_32FC(mapped.channels()));
  }];

  cv::Mat diff([self differenceAtBoundaryForSource:source target:target]);
  cv::Mat membrane([self membraneForBoundaryDifference:diff]);

  cv::Rect roi(cv::Rect(0, 0, self.output.size.width, self.output.size.height));
  cv::Mat membraneHalfFloat;
  LTConvertMat(membrane(roi), &membraneHalfFloat, CV_16FC(membrane.channels()));
  [self.output load:membraneHalfFloat];
}

- (cv::Mat)differenceAtBoundaryForSource:(const cv::Mat &)source target:(const cv::Mat &)target {
  cv::Mat diff(source.size(), source.type());

  // T - S.
  vDSP_vsub((const float *)source.data, 1, (const float *)target.data, 1, (float *)diff.data, 1,
            source.total() * source.channels());
  // Leave only diff at the boundary.
  vDSP_vmul((const float *)diff.data, 1, (const float *)_boundaryMultipleChannels.data, 1,
            (float *)diff.data, 1, diff.total() * diff.channels());

  return diff;
}

- (cv::Mat)membraneForBoundaryDifference:(const cv::Mat &)diff {
  cv::Mat paddedDiff = cv::Mat::zeros(self.paddedWorkingSize, diff.type());
  diff.copyTo(paddedDiff(self.unpaddedRect));

  // Calculate diff (*) kernel.
  Matrices paddedDiffChannels;
  cv::split(paddedDiff, paddedDiffChannels);
  Matrices membraneChannels;
  cv::Mat1f paddedErf(paddedDiff.size());

  // In case of an RGBA image, the membrane alpha channel is filled with zeros.
  NSUInteger channelsForConvolving = paddedDiffChannels.size() == 4 ? 3 : paddedDiffChannels.size();
  for (NSUInteger i = 0; i < channelsForConvolving; ++i) {
    @autoreleasepool {
      cv::Mat1f paddedErf([self convolveKernelWith:paddedDiffChannels[i]]);
      cv::Mat1f membrane;
      cv::divide(paddedErf(self.unpaddedRect), _paddedChi(self.unpaddedRect), membrane);

      membraneChannels.push_back(membrane);
    }
  }

  if (paddedDiffChannels.size() == 4) {
    membraneChannels.push_back(cv::Mat1f::zeros(self.unpaddedRect.size()));
  }

  cv::Mat membrane;
  cv::merge(membraneChannels, membrane);

  return membrane;
}

/// Assumes the paddedMat has the relevant mat centered in a zero-padded mat. The size of the padded
/// mat is twice the size of the mat holding the relevant information. This is required since the
/// convolution is cyclic, meaning it will take information from the other side of the mat for some
/// pixels. With zeros-padded mat, this information will not have any effect on the actual data we
/// want to convolve.
- (cv::Mat1f)convolveKernelWith:(const cv::Mat1f &)paddedMat {
  cv::Mat1f result(paddedMat.size());
  LTFFTConvolutionProcessor *processor =
      [[LTFFTConvolutionProcessor alloc]
       initWithFirstTransformedOperand:self.paddedTransformedKernel secondOperand:paddedMat
       output:&result];
  [processor process];

  return result;
}

#pragma mark -
#pragma mark Source and target quads
#pragma mark -

- (void)setSourceQuad:(LTQuad *)sourceQuad {
  _sourceQuad = sourceQuad;
  self.sourceResizer.inputQuad = sourceQuad;
}

- (void)setTargetQuad:(LTQuad *)targetQuad {
  _targetQuad = targetQuad;
  self.targetResizer.inputQuad = targetQuad;
}

#pragma mark -
#pragma mark Working rects
#pragma mark -

- (CGRect)maskWorkingRect {
  return CGRectFromOriginAndSize(CGPointZero, self.output.size);
}

- (cv::Size)paddedWorkingSize {
  return cv::Size(self.workingSize.width * 2, self.workingSize.height * 2);
}

- (cv::Rect)unpaddedRect {
  return cv::Rect(self.workingSize.width / 2, self.workingSize.height / 2,
                  self.workingSize.width, self.workingSize.height);
}

@end
