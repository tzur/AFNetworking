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
#import "LTRectCopyProcessor.h"
#import "LTRotatedRect.h"
#import "LTSplitComplexMat.h"
#import "LTTexture+Factory.h"

@interface LTPatchSolverProcessor () {
  /// Single channel float boundary.
  cv::Mat1f _boundarySingle;
  /// 4-channel float boundary. This is a duplicated 4-channel version of \c _boundarySingle.
  cv::Mat4f _boundaryRGBA;
  /// Boundary convoluted with the kernel.
  cv::Mat1f _paddedChi;
}

/// Mask used to select part of \c sourceRect to copy.
@property (strong, nonatomic) LTTexture *mask;

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
@property (strong, nonatomic) LTRectCopyProcessor *sourceResizer;

/// Resizer of target to working size.
@property (strong, nonatomic) LTRectCopyProcessor *targetResizer;

/// Resizer of mask to working size.
@property (strong, nonatomic) LTRectCopyProcessor *maskResizer;

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
  LTParameterAssert(output.precision == LTTexturePrecisionHalfFloat,
                    @"Output texture must be of half-float precision");
  if (self = [super init]) {
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;

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
  self.sourceRect = [LTRotatedRect rect:CGRectFromSize(self.source.size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromSize(self.source.size)];
}

- (void)processMaskIfNeeded {
  if (_paddedChi.empty() || ![self.lastProcessedMaskGenerationID isEqual:self.mask.generationID]) {
    [self createBoundary];
    [self calculateChi];
    self.lastProcessedMaskGenerationID = self.mask.generationID;
  }
}

- (void)createTransformedKernel {
  cv::Mat1f paddedKernel = LTPatchKernelCreate(self.paddedWorkingSize);

  self.paddedTransformedKernel = [[LTSplitComplexMat alloc] init];
  LTFFTProcessor *processor =
      [[LTFFTProcessor alloc] initWithRealInput:paddedKernel output:self.paddedTransformedKernel];
  [processor process];
}

- (void)createResizersAndTextures {
  self.sourceResized = [LTTexture byteRGBATextureWithSize:self.workingSize];
  self.targetResized = [LTTexture byteRGBATextureWithSize:self.workingSize];
  self.maskResized = [LTTexture byteRGBATextureWithSize:self.workingSize];

  static const LTVector4 kBlack = LTVector4(0, 0, 0, 0);
  [self.sourceResized clearWithColor:kBlack];
  [self.targetResized clearWithColor:kBlack];
  [self.maskResized clearWithColor:kBlack];

  self.sourceResizer = [[LTRectCopyProcessor alloc] initWithInput:self.source
                                                           output:self.sourceResized];
  self.targetResizer = [[LTRectCopyProcessor alloc] initWithInput:self.target
                                                           output:self.targetResized];
  self.maskResizer = [[LTRectCopyProcessor alloc] initWithInput:self.mask
                                                         output:self.maskResized];

  self.sourceResizer.inputRect = self.sourceRect;
  self.sourceResizer.outputRect = [LTRotatedRect rect:self.maskWorkingRect];
  self.targetResizer.inputRect = self.targetRect;
  self.targetResizer.outputRect = [LTRotatedRect rect:self.maskWorkingRect];
  self.maskResizer.outputRect = [LTRotatedRect rect:self.maskWorkingRect];
}

#pragma mark -
#pragma mark Boundary calculation
#pragma mark -

- (void)createBoundary {
  [self.maskResizer process];

  LTTexture *boundary = [LTTexture textureWithSize:self.workingSize
                                         precision:LTTexturePrecisionByte
                                            format:LTTextureFormatRed
                                    allocateMemory:YES];
  LTPatchBoundaryProcessor *processor = [[LTPatchBoundaryProcessor alloc]
                                         initWithInput:self.maskResized output:boundary];
  [processor process];

  // Convert to 1 and 4-channel float.
  [boundary mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &_boundarySingle, CV_32F);
  }];
  cv::merge({_boundarySingle, _boundarySingle, _boundarySingle, _boundarySingle}, _boundaryRGBA);
}

- (void)calculateChi {
  cv::Mat1f paddedBoundarySingle = cv::Mat1f::zeros(self.paddedWorkingSize);
  _boundarySingle.copyTo(paddedBoundarySingle(self.unpaddedRect));

  _paddedChi = [self convolveKernelWith:paddedBoundarySingle];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self processMaskIfNeeded];

  // TODO: (yaron) optional performance boost: process textures that their rect has been changed
  // only.
  [self.sourceResizer process];
  [self.targetResizer process];

  // TODO: (yaron) optional performance boost is to move all GPU operations in this processor to CPU
  // for small working sizes. This will avoid the 3-4ms of GPU->CPU synchronization that is occurred
  // when mapping the images for reading.
  __block cv::Mat4f source, target;
  [self.sourceResized mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &source, CV_32FC4);
  }];
  [self.targetResized mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &target, CV_32FC4);
  }];

  cv::Mat4f diff([self differenceAtBoundaryForSource:source target:target]);
  cv::Mat4f membrane([self membraneForBoundaryDifference:diff]);

  cv::Rect roi(cv::Rect(0, 0, self.output.size.width, self.output.size.height));
  cv::Mat4hf membraneHalfFloat;
  LTConvertMat(membrane(roi), &membraneHalfFloat, membraneHalfFloat.type());
  [self.output load:membraneHalfFloat];
}

- (cv::Mat4f)differenceAtBoundaryForSource:(const cv::Mat4f &)source
    target:(const cv::Mat4f &)target {
  cv::Mat4f diff(source.size());

  // T - S.
  vDSP_vsub((const float *)source.data, 1, (const float *)target.data, 1, (float *)diff.data, 1,
            source.total() * source.channels());
  // Leave only diff at the boundary.
  vDSP_vmul((const float *)diff.data, 1, (const float *)_boundaryRGBA.data, 1,
            (float *)diff.data, 1, diff.total() * diff.channels());

  return diff;
}

- (cv::Mat4f)membraneForBoundaryDifference:(const cv::Mat4f &)diff {
  cv::Mat4f paddedDiff = cv::Mat4f::zeros(self.paddedWorkingSize);
  diff.copyTo(paddedDiff(self.unpaddedRect));

  // Calculate diff (*) kernel.
  Matrices paddedDiffChannels;
  cv::split(paddedDiff, paddedDiffChannels);
  Matrices membraneChannels;
  cv::Mat1f paddedErf(paddedDiff.size());

  for (int i = 0; i < 3; ++i) {
    @autoreleasepool {
      cv::Mat1f paddedErf([self convolveKernelWith:paddedDiffChannels[i]]);
      cv::Mat1f membrane;
      cv::divide(paddedErf(self.unpaddedRect), _paddedChi(self.unpaddedRect), membrane);

      membraneChannels.push_back(membrane);
    }
  }

  membraneChannels.push_back(cv::Mat1f::zeros(self.unpaddedRect.size()));
  cv::Mat4f membrane;
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
#pragma mark Source and target rects
#pragma mark -

- (void)setSourceRect:(LTRotatedRect *)sourceRect {
  _sourceRect = sourceRect;
  self.sourceResizer.inputRect = sourceRect;
}

- (void)setTargetRect:(LTRotatedRect *)targetRect {
  _targetRect = targetRect;
  self.targetResizer.inputRect = targetRect;
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
