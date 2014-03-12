// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTBoundaryExtractor.h"
#import "LTCGExtensions.h"
#import "LTFFTConvolutionProcessor.h"
#import "LTFFTProcessor.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
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
  cv::Mat1f _chi;
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

/// Resizer of source to working size.
@property (strong, nonatomic) LTRectCopyProcessor *sourceResizer;

/// Resizer of target to working size.
@property (strong, nonatomic) LTRectCopyProcessor *targetResizer;

/// Resizer of mask to working size.
@property (strong, nonatomic) LTRectCopyProcessor *maskResizer;

/// FFT result of the kernel.
@property (strong, nonatomic) LTSplitComplexMat *transformedKernel;

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
  LTParameterAssert(LTIsPowerOfTwo(std::max(output.size)),
                    @"Largest dimension of the output must be a power of two");
  LTParameterAssert(output.precision == LTTexturePrecisionHalfFloat,
                    @"Output texture must be of half-float precision");
  if (self = [super init]) {
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;

    self.workingSize = CGSizeMake(std::max(self.output.size), std::max(self.output.size));

    [self createTransformedKernel];
    [self createResizersAndTextures];

    [self maskUpdated];

    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.sourceRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.source.size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.source.size)];
}

- (void)maskUpdated {
  [self createBoundary];
  [self calculateChi];
}

- (void)createTransformedKernel {
  cv::Mat1f kernel = LTPatchKernelCreate(cv::Size(self.workingSize.width,
                                                  self.workingSize.height));

  self.transformedKernel = [[LTSplitComplexMat alloc] init];
  LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithRealInput:kernel
                                                                 output:self.transformedKernel];
  [processor process];
}

- (void)createResizersAndTextures {
  self.sourceResized = [LTTexture byteRGBATextureWithSize:self.workingSize];
  self.targetResized = [LTTexture byteRGBATextureWithSize:self.workingSize];
  self.maskResized = [LTTexture byteRGBATextureWithSize:self.workingSize];

  const GLKVector4 kBlack = GLKVector4Make(0, 0, 0, 0);
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
  LTBoundaryExtractor *processor = [[LTBoundaryExtractor alloc]
                                    initWithInput:self.maskResized output:boundary];
  [processor process];

  // Convert to 1 and 4-channel float.
  [boundary mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &_boundarySingle, CV_32F);
  }];
  cv::merge({_boundarySingle, _boundarySingle, _boundarySingle, _boundarySingle}, _boundaryRGBA);
}

- (void)calculateChi {
  _chi = [self convolveKernelWith:_boundarySingle];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (LTSingleTextureOutput *)process {
  // TODO: (yaron) optional performance boost: process textures that their rect has been changed
  // only.
  LTSingleTextureOutput *sourceOutput = [self.sourceResizer process];
  LTSingleTextureOutput *targetOutput = [self.targetResizer process];

  // TODO: (yaron) optional performance boost is to move all GPU operations in this processor to CPU
  // for small working sizes. This will avoid the 3-4ms of GPU->CPU synchronization that is occurred
  // when mapping the images for reading.
  __block cv::Mat4f source, target, maskMat;
  [sourceOutput.texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &source, CV_32FC4);
  }];
  [targetOutput.texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTConvertMat(mapped, &target, CV_32FC4);
  }];

  cv::Mat4f diff([self differenceAtBoundaryForSource:source target:target]);
  cv::Mat4f membrane([self membraneForBoundaryDifference:diff]);

  cv::Rect roi(cv::Rect(0, 0, self.output.size.width, self.output.size.height));
  cv::Mat4hf membraneHalfFloat;
  LTConvertMat(membrane(roi), &membraneHalfFloat, membraneHalfFloat.type());
  [self.output load:membraneHalfFloat];

  return [[LTSingleTextureOutput alloc] initWithTexture:self.output];
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
  // Calculate diff (*) kernel.
  Matrices diffChannels;
  cv::split(diff, diffChannels);
  Matrices membraneChannels;
  cv::Mat1f erf(diff.size());

  for (int i = 0; i < 3; ++i) {
    cv::Mat1f erf([self convolveKernelWith:diffChannels[i]]);

    cv::Mat1f membrane;
    cv::divide(erf, _chi, membrane);
    LTInPlaceFFTShift(&membrane);
    membraneChannels.push_back(membrane);
  }

  membraneChannels.push_back(cv::Mat1f::zeros(erf.size()));
  cv::Mat4f membrane;
  cv::merge(membraneChannels, membrane);

  return membrane;
}

- (cv::Mat1f)convolveKernelWith:(const cv::Mat1f &)mat {
  cv::Mat1f result(mat.size());

  LTFFTConvolutionProcessor *processor = [[LTFFTConvolutionProcessor alloc]
                                          initWithFirstTransformedOperand:self.transformedKernel
                                          secondOperand:mat
                                          output:&result];
  processor.shiftResult = NO;
  [processor process];

  return result;
}

#pragma mark -
#pragma mark Model values
#pragma mark -

- (void)setObject:(id __unused)obj forKeyedSubscript:(NSString __unused *)key {
}

- (id)objectForKeyedSubscript:(NSString __unused *)key {
  return nil;
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

- (CGRect)workingRect {
  return CGRectFromOriginAndSize(CGPointZero, self.workingSize);
}

- (CGRect)maskWorkingRect {
  return CGRectFromOriginAndSize(CGPointZero, self.output.size);
}

@end
