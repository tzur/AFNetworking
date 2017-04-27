// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTDisplacementMapDrawer.h"

#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTDisplacementMapDrawerFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible modes for the adjustment fragment shader.
typedef NS_ENUM(NSUInteger, LTReshapeAdjustmentMode) {
  /// Reshape mode.
  LTReshapeAdjustmentModeReshape,
  /// Resize (bloat) mode.
  LTReshapeAdjustmentModeResize,
  /// Unwarp (restore) mode.
  LTReshapeAdjustmentModeUnwarp
};

@interface LTDisplacementMapDrawer ()

/// Drawer that is used for drawing on the displacement map texture.
@property (readonly, nonatomic) LTRectDrawer *adjustmentDrawer;

/// Framebuffer object used to update the displacement map texture.
@property (readonly, nonatomic) LTFbo *displacementMapFbo;

/// Factor used to reflect the corresponding deformed area aspect ratio in order to have accurate
/// distance calculations in normalized coordinates.
@property (nonatomic) CGSize aspectFactor;

@end

@implementation LTDisplacementMapDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDisplacementMap:(LTTexture *)displacementMap
                       deformedAreaSize:(CGSize)deformedAreaSize {
  return [self initWithDisplacementMap:displacementMap mask:[LTDisplacementMapDrawer defaultMask]
                      deformedAreaSize:deformedAreaSize];
}

+ (LTTexture *)defaultMask {
  return [LTTexture textureWithImage:cv::Mat1b(1, 1, (uchar)255)];
}

- (instancetype)initWithDisplacementMap:(LTTexture *)displacementMap mask:(LTTexture *)mask
                       deformedAreaSize:(CGSize)deformedAreaSize {
  LTParameterAssert(displacementMap);
  LTParameterAssert(mask);
  LTParameterAssert(deformedAreaSize.width > 0 && deformedAreaSize.height > 0,
                    @"deformedAreaSize must have positive values but input size is (%f, %f)",
                    deformedAreaSize.width, deformedAreaSize.height);

  if (self = [super init]) {
    _displacementMap = displacementMap;
    _displacementMapFbo = [[LTFboPool currentPool] fboWithTexture:self.displacementMap];

    [self createAdjustmentDrawerWithMask:mask];
    self.aspectFactor = [self aspectFactorFromSize:deformedAreaSize];
  }

  return self;
}

- (CGSize)aspectFactorFromSize:(CGSize)size {
  return size.width > size.height ?
      CGSizeMake(1.0, size.height / size.width) : CGSizeMake(size.width / size.height, 1.0);
}

- (void)createAdjustmentDrawerWithMask:(LTTexture *)mask {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTDisplacementMapDrawerFsh source]];
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures =
      @{[LTDisplacementMapDrawerFsh maskTexture]: mask};
  _adjustmentDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                              sourceTexture:self.displacementMap
                                           auxiliaryTextures:auxiliaryTextures];
}

#pragma mark -
#pragma mark Reshape
#pragma mark -

- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(const LTReshapeBrushParams &)params {
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh center]] =
      $(LTVector2(center * self.aspectFactor));
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh direction]] = $(LTVector2(direction));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeReshape brushParams:params];
}

- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(const LTReshapeBrushParams &)params {
  scale = (scale > 1) ? scale - 1 : -(1 / scale - 1);
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh scale]] = @(scale);
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh center]] =
      $(LTVector2(center * self.aspectFactor));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeResize brushParams:params];
}

- (void)unwarpWithCenter:(CGPoint)center brushParams:(const LTReshapeBrushParams &)params {
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh center]] =
      $(LTVector2(center * self.aspectFactor));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeUnwarp brushParams:params];
}

- (void)adjustMeshWithMode:(LTReshapeAdjustmentMode)mode
               brushParams:(const LTReshapeBrushParams &)params {
  [self prepareDrawerForMode:mode params:params];

  // Use the scissor box to make sure the boundary vertices are not affected by the adjustment.
  // Note that binding an fbo resets the scissor box, so we need to bind first, then update the
  // scissor box, and finally use drawRect:inFramebufferWithSize:fromRect: for drawing.
  [self.displacementMapFbo bindAndDraw:^{
    [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
      context.scissorTestEnabled = YES;
      context.scissorBox = CGRectInset(CGRectFromSize(self.displacementMap.size), 1, 1);
      [self.adjustmentDrawer drawRect:CGRectFromSize(self.displacementMap.size)
                inFramebufferWithSize:self.displacementMapFbo.size
                             fromRect:CGRectFromSize(self.displacementMap.size)];
    }];
  }];
}

- (void)prepareDrawerForMode:(LTReshapeAdjustmentMode)mode
                      params:(const LTReshapeBrushParams &)params {
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh mode]] = @(mode);
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh diameter]] = @(params.diameter);
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh density]] = @(params.density);
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh pressure]] = @(params.pressure);
}

- (void)resetDisplacementMap {
  [self.displacementMap clearColor:LTVector4::zeros()];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setAspectFactor:(CGSize)aspectFactor {
  _aspectFactor = aspectFactor;
  self.adjustmentDrawer[[LTDisplacementMapDrawerFsh aspectFactor]] = $(LTVector2(aspectFactor));
}

@end

NS_ASSUME_NONNULL_END
