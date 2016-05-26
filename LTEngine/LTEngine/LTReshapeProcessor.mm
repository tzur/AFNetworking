// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTReshapeProcessor.h"

#import "LTDisplacementMapDrawer.h"
#import "LTMeshProcessor.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTReshapeProcessor ()

/// Drawer for adjusting the mesh displacement texture to reshape operations.
@property (readonly, nonatomic) LTDisplacementMapDrawer *displacementMapDrawer;

/// Internally used mesh processor.
@property (strong, nonatomic) LTMeshProcessor *meshProcessor;

/// Initializes the processor with a \c displacementMapDrawer and a \c meshProcessor. \c
/// meshDisplacementTexture property is set from the \c displacementMapDrawer displacement map. \c
/// \c inputTexture, \c outputTexture, \c inputSize and \c outputSize properties are determined from
/// the \c meshProcessor corresponding properties. \c displacementMapDrawer is used for adjusting
/// the displacement map texture to reshape operations. \c meshProcessor is used to deform its input
/// texture using the same displacement map texture into its output textute. Therefore, \c
/// displacementMapDrawer.displacementMap and \c meshProcessor.meshDisplacementTexture must be
/// identical or an error will be raised.
- (instancetype)initWithDisplacementMapDrawer:(LTDisplacementMapDrawer *)displacementMapDrawer
                                meshProcessor:(LTMeshProcessor *)meshProcessor
    NS_DESIGNATED_INITIALIZER;

@end

@implementation LTReshapeProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [self initWithInput:input mask:nil output:output];
}

- (instancetype)initWithInput:(LTTexture *)input mask:(nullable LTTexture *)mask
                       output:(LTTexture *)output {
  return [self initWithFragmentSource:[LTPassthroughShaderFsh source]
                                input:input mask:mask output:output];
}

- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                                  mask:(nullable LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(fragmentSource);
  LTParameterAssert(input);
  LTParameterAssert(output);

  if (self = [super init]) {
    LTTexture *displacementMap = [self displacementMapForTexture:input];
    _meshProcessor = [[LTMeshProcessor alloc] initWithFragmentSource:fragmentSource input:input
                                             meshDisplacementTexture:displacementMap output:output];
    _displacementMapDrawer = [self displacementMapDrawerForDisplacementMap:displacementMap mask:mask
                                                                      size:input.size];
    [self.displacementMapDrawer resetDisplacementMap];
  }

  return self;
}

- (LTTexture *)displacementMapForTexture:(LTTexture *)texture {
  LTTexture *displacementMap =
      [LTTexture textureWithSize:[self displacementMapSizeForTexture:texture]
                     pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];

  return displacementMap;
}

- (CGSize)displacementMapSizeForTexture:(LTTexture *)texture {
  // TODO:(amit) add a device-dependant logic to determine the maximum size.
  return std::ceil(texture.size / 8) + CGSizeMakeUniform(1);
}

- (LTDisplacementMapDrawer *)displacementMapDrawerForDisplacementMap:(LTTexture *)displacementMap
                                                                mask:(nullable LTTexture *)mask
                                                                size:(CGSize)size {
  return mask ? [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap mask:mask
                                                        deformedAreaSize:size] :
                [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap
                                                        deformedAreaSize:size];
}

- (instancetype)initWithDisplacementMapDrawer:(LTDisplacementMapDrawer *)displacementMapDrawer
                                meshProcessor:(LTMeshProcessor *)meshProcessor {
  LTParameterAssert(displacementMapDrawer);
  LTParameterAssert(meshProcessor);
  LTParameterAssert(displacementMapDrawer.displacementMap == meshProcessor.meshDisplacementTexture,
                    @"displacementMapDrawer.displacementMap and "
                    @"meshProcessor.meshDisplacementTexture must be identical but input "
                    @"displacementMapDrawer.displacementMap points to %p and input "
                    @"meshProcessor.meshDisplacementTexture points to %p",
                    displacementMapDrawer.displacementMap, meshProcessor.meshDisplacementTexture);

  if (self = [super init]) {
    _displacementMapDrawer = displacementMapDrawer;
    [self.displacementMapDrawer resetDisplacementMap];
    _meshProcessor = meshProcessor;
  }

  return self;
}

#pragma mark -
#pragma mark Process
#pragma mark -

- (void)process {
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
  [self.displacementMapDrawer resetDisplacementMap];
}

#pragma mark -
#pragma mark Reshape
#pragma mark -

- (void)reshapeWithCenter:(CGPoint)center direction:(CGPoint)direction
              brushParams:(const LTReshapeBrushParams &)params {
  [self.displacementMapDrawer reshapeWithCenter:center direction:direction brushParams:params];
}

- (void)resizeWithCenter:(CGPoint)center scale:(CGFloat)scale
             brushParams:(const LTReshapeBrushParams &)params {
  [self.displacementMapDrawer resizeWithCenter:center scale:scale brushParams:params];
}

- (void)unwarpWithCenter:(CGPoint)center brushParams:(const LTReshapeBrushParams &)params {
  [self.displacementMapDrawer unwarpWithCenter:center brushParams:params];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTTexture *)meshDisplacementTexture {
  return self.meshProcessor.meshDisplacementTexture;
}

- (CGSize)inputSize {
  return self.meshProcessor.inputSize;
}

- (CGSize)outputSize {
  return self.meshProcessor.outputSize;
}

- (LTTexture *)inputTexture {
  return self.meshProcessor.inputTexture;
}

- (LTTexture *)outputTexture {
  return self.meshProcessor.outputTexture;
}

@end

NS_ASSUME_NONNULL_END
