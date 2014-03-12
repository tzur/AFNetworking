// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTCGExtensions.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTPatchCompositorProcessor.h"
#import "LTPatchSolverProcessor.h"
#import "LTRectCopyProcessor.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

@interface LTPatchProcessor ()

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

/// Size of the mask given the working size. This size will never be larger than \c workingSize, and
/// one of its dimensions will be equal to one of the corresponding dimension of \c workingSize, so
/// the mask is 'aspect fitted' to \c workingSize.
@property (nonatomic) CGSize maskWorkingSize;

@end

@implementation LTPatchProcessor

static const CGFloat kDefaultWorkingSize = 64;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMask:(LTTexture *)mask source:(LTTexture *)source
                      target:(LTTexture *)target output:(LTTexture *)output {
  LTParameterAssert(target.size == output.size, @"Output size must equal target size");
  if (self = [super init]) {
    self.mask = mask;
    self.source = source;
    self.target = target;
    self.output = output;

    self.workingSize = CGSizeMake(kDefaultWorkingSize, kDefaultWorkingSize);

    [self setDefaultValues];
  }
  return self;
}

- (void)setWorkingSize:(CGSize)workingSize {
  LTParameterAssert(LTIsPowerOfTwo(workingSize), @"Working size must be a power of two");

  if (_workingSize == workingSize) {
    return;
  }
  _workingSize = workingSize;

  // TODO:(yaron) some operations here can be calculated on the set of possible working sizes,
  // sparing time when switching.
  [self updateMaskWorkingSize];
  [self createMembraneTexture];
  [self createSolver];
  [self createCompositor];
}

- (void)setDefaultValues {
  self.sourceRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.source.size)];
  self.targetRect = [LTRotatedRect rect:CGRectFromOriginAndSize(CGPointZero, self.source.size)];
}

- (void)maskUpdated {
  [self.solver maskUpdated];
}

- (void)updateMaskWorkingSize {
  double ratio = MIN((double)self.workingSize.width / self.mask.size.width,
                     (double)self.workingSize.height / self.mask.size.height);
  if (ratio <= 1) {
    self.maskWorkingSize = std::floor(CGSizeMake(self.mask.size.width * ratio,
                                                 self.mask.size.height * ratio));
  } else {
    self.maskWorkingSize = self.mask.size;
  }
}

- (void)createMembraneTexture {
  self.membrane = [LTTexture textureWithSize:self.maskWorkingSize
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
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (LTSingleTextureOutput *)process {
  [self.solver process];
  return [self.compositor process];
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
  self.solver.targetRect = sourceRect;
  self.compositor.sourceRect = sourceRect;
}

- (void)setTargetRect:(LTRotatedRect *)targetRect {
  _targetRect = targetRect;
  self.solver.targetRect = targetRect;
  self.compositor.targetRect = targetRect;
}

@end
