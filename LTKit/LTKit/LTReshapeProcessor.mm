// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTReshapeProcessor.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTMeshProcessor.h"
#import "LTProgramFactory.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTReshapeProcessorFsh.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

// Possible modes for the adjustment fragment shader.
typedef NS_ENUM(NSUInteger, LTReshapeAdjustmentMode) {
  LTReshapeAdjustmentModeReshape,
  LTReshapeAdjustmentModeResize,
  LTReshapeAdjustmentModeUnwarp
};

@interface LTReshapeProcessor ()

/// Mask texture used for freezing certain areas while making adjustments to the mesh texture.
@property (strong, nonatomic) LTTexture *maskTexture;

/// Framebuffer object used to update the mesh texture.
@property (strong, nonatomic) LTFbo *meshFbo;

/// Internally used mesh processor.
@property (strong, nonatomic) LTMeshProcessor *meshProcessor;

/// Used for adjusting the mesh displacement texture.
@property (strong, nonatomic) LTRectDrawer *adjustmentDrawer;

/// Factor used to reflect the texture's aspect ratio in order to have accurate distance
/// calculations in normalized coordinates.
@property (readonly, nonatomic) CGSize aspectFactor;

@end

@implementation LTReshapeProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [self initWithInput:input mask:nil output:output];
}

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  return [self initWithFragmentSource:[LTPassthroughShaderFsh source]
                                input:input mask:mask output:output];
}

- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                                  mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(fragmentSource);
  LTParameterAssert(input);
  LTParameterAssert(output);
  if (self = [super init]) {
    self.meshProcessor =
        [[LTMeshProcessor alloc] initWithFragmentSource:fragmentSource input:input
                                               meshSize:[self meshTextureSizeForInput:input]
                                                 output:output];
    self.maskTexture = mask ?: self.defaultMaskTexture;
    self.meshFbo = [[LTFbo alloc] initWithTexture:self.meshDisplacementTexture];
    [self createAdjustmentDrawer];
  }
  return self;
}

- (CGSize)meshTextureSizeForInput:(LTTexture *)input {
  LTParameterAssert(input);
  // TODO:(amit) add a device-dependant logic to determine the maximum size.
  return std::ceil(input.size / 8) + CGSizeMakeUniform(1);
}

- (void)createAdjustmentDrawer {
  LTParameterAssert(self.meshDisplacementTexture);
  LTParameterAssert(self.maskTexture);
  LTBasicProgramFactory *factory = [[LTBasicProgramFactory alloc] init];
  LTProgram *program = [factory programWithVertexSource:[LTPassthroughShaderVsh source]
                                         fragmentSource:[LTReshapeProcessorFsh source]];
  self.adjustmentDrawer =
      [[LTRectDrawer alloc] initWithProgram:program sourceTexture:self.meshDisplacementTexture
        auxiliaryTextures:@{[LTReshapeProcessorFsh maskTexture]: self.maskTexture}];
}

#pragma mark -
#pragma mark Process
#pragma mark -

- (void)process {
  [self.outputTexture clearWithColor:LTVector4Zero];
  [self.meshProcessor process];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self.meshProcessor processToFramebufferWithSize:size outputRect:rect];
}

- (void)processInRect:(CGRect)rect {
  [self.meshProcessor processInRect:rect];
}

#pragma mark -
#pragma mark Reset
#pragma mark -

- (void)resetMesh {
  [self.meshProcessor resetMesh];
}

#pragma mark -
#pragma mark Reshape
#pragma mark -

- (void)adjustMeshWithMode:(LTReshapeAdjustmentMode)mode brushParams:(LTReshapeBrushParams)params {
  [self prepareDrawerForMode:mode params:params];

  // Use the scissor box to make sure the boundary vertices are not affected by the adjustment.
  // Note that binding an fbo resets the scissor box, so we need to bind first, then update the
  // scissor box, and finally use drawRect:inFramebufferWithSize:fromRect: for drawing.
  [self.meshFbo bindAndDraw:^{
    [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
      context.scissorTestEnabled = YES;
      context.scissorBox = CGRectInset(CGRectFromSize(self.meshDisplacementTexture.size), 1, 1);
      [self.adjustmentDrawer drawRect:CGRectFromSize(self.meshDisplacementTexture.size)
                inFramebufferWithSize:self.meshFbo.size
                             fromRect:CGRectFromSize(self.meshDisplacementTexture.size)];
    }];
  }];
}

- (void)prepareDrawerForMode:(LTReshapeAdjustmentMode)mode params:(LTReshapeBrushParams)params {
  self.adjustmentDrawer[[LTReshapeProcessorFsh mode]] = @(mode);
  self.adjustmentDrawer[[LTReshapeProcessorFsh diameter]] = @(params.diameter);
  self.adjustmentDrawer[[LTReshapeProcessorFsh density]] = @(params.density);
  self.adjustmentDrawer[[LTReshapeProcessorFsh pressure]] = @(params.pressure);
  self.adjustmentDrawer[[LTReshapeProcessorFsh aspectFactor]] = $(LTVector2(self.aspectFactor));
}

- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(LTReshapeBrushParams)params {
  self.adjustmentDrawer[[LTReshapeProcessorFsh center]] = $(LTVector2(center * self.aspectFactor));
  self.adjustmentDrawer[[LTReshapeProcessorFsh direction]] = $(LTVector2(direction));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeReshape brushParams:params];
}

- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(LTReshapeBrushParams)params {
  scale = (scale > 1) ? scale - 1 : -(1 / scale - 1);
  self.adjustmentDrawer[[LTReshapeProcessorFsh scale]] = @(scale);
  self.adjustmentDrawer[[LTReshapeProcessorFsh center]] = $(LTVector2(center * self.aspectFactor));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeResize brushParams:params];
}

- (void)unwarpWithCenter:(CGPoint)center brushParams:(LTReshapeBrushParams)params {
  self.adjustmentDrawer[[LTReshapeProcessorFsh center]] = $(LTVector2(center * self.aspectFactor));
  [self adjustMeshWithMode:LTReshapeAdjustmentModeUnwarp brushParams:params];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTTexture *)inputTexture {
  return self.meshProcessor.inputTexture;
}

- (LTTexture *)outputTexture {
  return self.meshProcessor.outputTexture;
}

- (CGSize)aspectFactor {
  return self.inputSize.width > self.inputSize.height ?
      CGSizeMake(1.0, self.inputSize.height / self.inputSize.width) :
      CGSizeMake(self.inputSize.width / self.inputSize.height, 1.0);
}

- (LTTexture *)defaultMaskTexture {
  LTTexture *texture = [LTTexture textureWithImage:cv::Mat1b(1, 1)];
  [texture clearWithColor:LTVector4One];
  texture.minFilterInterpolation = LTTextureInterpolationNearest;
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
  return texture;
}

- (CGSize)inputSize {
  return self.meshProcessor.inputSize;
}

- (CGSize)outputSize {
  return self.meshProcessor.outputSize;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (LTTexture *)meshDisplacementTexture {
  return self.meshProcessor.meshDisplacementTexture;
}

@end
