// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchProcessor.h"

#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTPatchCompositorProcessor.h"
#import "LTPatchSolverProcessor.h"
#import "LTRectCopyProcessor.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

#pragma mark -
#pragma mark LTInternalPatchProcessor
#pragma mark -

/// Internal patch processor, handling a single working size.
@interface LTInternalPatchProcessor : LTImageProcessor

/// Initializes a new patch processor.
///
/// @param workingSize defines the size which the patch calculations is done at. Making this size
/// smaller will give a boost in performance, but will yield a less accurate result. For each
/// working size, both given dimensions must be a power of two. The first given working size will be
/// the default one.
/// @param mask mask texture used to define the patch region.
/// @param source texture used to take texture from.
/// @param target target texture used as the base layer.
/// @param output contains the processing result. Size must be equal to \c target size.
- (instancetype)initWithWorkingSize:(CGSize)workingSize mask:(LTTexture *)mask
                             source:(LTTexture *)source target:(LTTexture *)target
                             output:(LTTexture *)output;

/// Mask used to select part of \c sourceRect to copy.
@property (strong, nonatomic) LTTexture *mask;

/// Solution of the Patch PDE.
@property (strong, nonatomic) LTTexture *membrane;

/// Source texture, used to copy the data from.
@property (strong, nonatomic) LTTexture *source;

/// Target texture, used to copy the data to.
@property (strong, nonatomic) LTTexture *target;

/// Output result texture.
@property (strong, nonatomic) LTTexture *output;

/// Solver of the Patch PDE, yielding a valid membrane.
@property (strong, nonatomic) LTPatchSolverProcessor *solver;

/// Compositor used to combine source, target, mask and membrane together.
@property (strong, nonatomic) LTPatchCompositorProcessor *compositor;

/// Size that the patch calculations is done at. Making this size smaller will give a boost in
/// performance, but will yield a less accurate result. Given size must be one of the sizes given in
/// the initializer. The default value is the first working size given in the initializer.
@property (nonatomic) CGSize workingSize;

/// Rotated rect defining a region of interest in the source texture, which the data is copied from.
/// The default value is an axis aligned rect of (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Rotated rect defining a region of interest in the target texture, where the data is copied to.
/// Note that the size and orientation of the rect can be different than \c sourceRect, which will
/// cause a warping of the source rect to this rect. The default value is an axis aligned rect of
/// (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *targetRect;

/// Opacity of the source texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat sourceOpacity;
LTPropertyDeclare(CGFloat, sourceOpacity, SourceOpacity);

@end

@implementation LTInternalPatchProcessor

- (instancetype)initWithWorkingSize:(CGSize)workingSize mask:(LTTexture *)mask
                             source:(LTTexture *)source target:(LTTexture *)target
                             output:(LTTexture *)output {
  LTParameterAssert(target.size == output.size, @"Output size must equal target size");
  if (self = [super init]) {
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;
    self.workingSize = workingSize;

    [self setDefaultValues];
    [self createMembraneTexture];
    [self createSolver];
    [self createCompositor];
  }
  return self;
}

- (void)setDefaultValues {
  self.sourceRect = [LTRotatedRect rect:CGRectFromSize(self.source.size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromSize(self.source.size)];
}

/// Size of the mask given the working size. This size will never be larger than \c workingSize, and
/// one of its dimensions will be equal to one of the corresponding dimension of \c workingSize, so
/// the mask is 'aspect fitted' to \c workingSize.
- (CGSize)maskSizeForCurrentWorkingSize {
  double ratio = MIN((double)self.workingSize.width / self.mask.size.width,
                     (double)self.workingSize.height / self.mask.size.height);
  if (ratio <= 1) {
    return std::floor(CGSizeMake(self.mask.size.width * ratio, self.mask.size.height * ratio));
  } else {
    return self.mask.size;
  }
}

- (void)createMembraneTexture {
  self.membrane = [LTTexture textureWithSize:[self maskSizeForCurrentWorkingSize]
                                   precision:LTTexturePrecisionHalfFloat
                                      format:LTTextureFormatRGBA allocateMemory:YES];
}

- (void)createSolver {
  self.solver = [[LTPatchSolverProcessor alloc] initWithMask:self.mask source:self.source
                                                      target:self.target output:self.membrane];
  self.solver.sourceRect = self.sourceRect;
  self.solver.targetRect = self.targetRect;
}

- (void)createCompositor {
  self.compositor = [[LTPatchCompositorProcessor alloc]
                     initWithSource:self.source target:self.target membrane:self.membrane
                     mask:self.mask output:self.output];
  self.compositor.sourceRect = self.sourceRect;
  self.compositor.targetRect = self.targetRect;
  self.compositor.sourceOpacity = self.sourceOpacity;
}

- (void)process {
  [self.solver process];
  [self.compositor process];
}

LTPropertyProxy(CGFloat, sourceOpacity, SourceOpacity, self.compositor);

- (void)setSourceRect:(LTRotatedRect *)sourceRect {
  _sourceRect = sourceRect;
  self.solver.sourceRect = sourceRect;
  self.compositor.sourceRect = sourceRect;
}

- (void)setTargetRect:(LTRotatedRect *)targetRect {
  _targetRect = targetRect;
  self.solver.targetRect = targetRect;
  self.compositor.targetRect = targetRect;
}

@end

#pragma mark -
#pragma mark LTPatchProcessor
#pragma mark -

@interface LTPatchProcessor ()

/// Mask used to select part of \c sourceRect to copy.
@property (strong, nonatomic) LTTexture *mask;

/// Source texture, used to copy the data from.
@property (strong, nonatomic) LTTexture *source;

/// Target texture, used to copy the data to.
@property (strong, nonatomic) LTTexture *target;

/// Output result texture.
@property (strong, nonatomic) LTTexture *output;

/// Maps \c CGSize of working size to its associated processor.
@property (strong, nonatomic) NSMutableDictionary *workingSizeToProcessor;

/// Set of possible working sizes.
@property (readwrite, nonatomic) CGSizes workingSizes;

/// Rect copy processor used to copy previous patched rect before drawing a new one.
@property (strong, nonatomic) LTRectCopyProcessor *rectCopyProcessor;

/// \c YES if processed at least once.
@property (nonatomic) BOOL didProcessAtLeastOnce;

@end

@implementation LTPatchProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithWorkingSizes:(CGSizes)workingSizes mask:(LTTexture *)mask
                              source:(LTTexture *)source target:(LTTexture *)target
                              output:(LTTexture *)output {
  LTParameterAssert(target.size == output.size, @"Output size must equal target size");
  if (self = [super init]) {
    self.workingSizes = workingSizes;
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;

    [self createInternalProcessors];
    [self setRectsForSize:source.size];
    [self createRectCopyProcessor];

    self.workingSize = workingSizes.front();
  }
  return self;
}

- (void)createInternalProcessors {
  self.workingSizeToProcessor = [NSMutableDictionary dictionary];
  for (CGSize size : self.workingSizes) {
    LTInternalPatchProcessor *processor = [[LTInternalPatchProcessor alloc]
                                           initWithWorkingSize:size mask:self.mask
                                           source:self.source target:self.target
                                           output:self.output];
    self.workingSizeToProcessor[$(size)] = processor;
  }
}

- (void)setRectsForSize:(CGSize)size {
  self.sourceRect = [LTRotatedRect rect:CGRectFromSize(size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromSize(size)];
}

- (void)createRectCopyProcessor {
  self.rectCopyProcessor = [[LTRectCopyProcessor alloc] initWithInput:self.target
                                                               output:self.output];
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTPatchProcessor, sourceRect),
      @instanceKeypath(LTPatchProcessor, targetRect),
      @instanceKeypath(LTPatchProcessor, workingSize),
      @instanceKeypath(LTPatchProcessor, sourceOpacity)
    ]];
  });

  return properties;
}

#pragma mark -
#pragma mark Working size
#pragma mark -

- (void)setWorkingSizes:(CGSizes)workingSizes {
  LTParameterAssert(workingSizes.size(), @"Working sizes must have at least one size");

  for (CGSize size : workingSizes) {
    LTParameterAssert(LTIsPowerOfTwo(size), @"Working size must be a power of two, got: %@",
                      NSStringFromCGSize(size));
  }

  _workingSizes.assign(workingSizes.begin(), workingSizes.end());
}

- (void)setWorkingSize:(CGSize)workingSize {
  const auto findResult = std::find(_workingSizes.begin(), _workingSizes.end(), workingSize);
  LTParameterAssert(findResult != _workingSizes.end(), @"Given workingSize %@ is not one of the "
                    "possible working sizes", NSStringFromCGSize(workingSize));

  _workingSize = workingSize;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  if (self.didProcessAtLeastOnce) {
    [self.rectCopyProcessor process];
  }
  
  [self.workingSizeToProcessor[$(self.workingSize)] process];

  [self updateRectCopyProcessorRects];
}

- (void)updateRectCopyProcessorRects {
  self.rectCopyProcessor.inputRect = self.targetRect;
  self.rectCopyProcessor.outputRect = self.targetRect;
  self.didProcessAtLeastOnce = YES;
}

#pragma mark -
#pragma mark Source and target rects
#pragma mark -

- (void)setSourceRect:(LTRotatedRect *)sourceRect {
  _sourceRect = sourceRect;
  for (LTInternalPatchProcessor *processor in self.workingSizeToProcessor.allValues) {
    processor.sourceRect = sourceRect;
  }
}

- (void)setTargetRect:(LTRotatedRect *)targetRect {
  _targetRect = targetRect;
  for (LTInternalPatchProcessor *processor in self.workingSizeToProcessor.allValues) {
    processor.targetRect = targetRect;
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, sourceOpacity, SourceOpacity, 0, 1, 1);
- (void)setSourceOpacity:(CGFloat)sourceOpacity {
  [self _verifyAndSetSourceOpacity:sourceOpacity];

  for (LTInternalPatchProcessor *processor in self.workingSizeToProcessor.allValues) {
    processor.sourceOpacity = sourceOpacity;
  }
}

@end
