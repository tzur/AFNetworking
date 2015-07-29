// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadMixerProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTProgramFactory.h"
#import "LTQuad.h"
#import "LTQuadDrawer.h"
#import "LTQuadMapping.h"
#import "LTRectCopyProcessor.h"
#import "LTShaderStorage+LTMixerFsh.h"
#import "LTShaderStorage+LTMixerVsh.h"
#import "LTSingleQuadDrawer.h"
#import "LTTexture.h"

@interface LTRectDrawer ()
@property (strong, nonatomic) LTProgram *program;
@end

@interface LTQuadMixerProcessor ()

/// Internally used quad drawer.
@property (strong, nonatomic) LTQuadDrawer *quadDrawer;

/// Mask mode used to mix the front and the back texture.
@property (nonatomic) LTMixerMaskMode maskMode;

/// Matrix determining the transformation applied to the front texture before mixing.
@property (nonatomic) GLKMatrix3 frontMatrix;

/// Matrix determining the transformation applied to the mask texture before mixing.
@property (nonatomic) GLKMatrix3 maskMatrix;

@end

@implementation LTQuadMixerProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front mask:(LTTexture *)mask
                      output:(LTTexture *)output maskMode:(LTMixerMaskMode)maskMode {
  LTParameterAssert(maskMode != LTMixerMaskModeFront || front.size == mask.size,
                    @"Front size (%g, %g) must equal mask size (%g, %g)",
                    front.size.width, front.size.height, mask.size.width, mask.size.height);
  LTParameterAssert(maskMode != LTMixerMaskModeBack || back.size == mask.size,
                    @"Back size (%g, %g) must equal mask size (%g, %g)",
                    back.size.width, back.size.height, mask.size.width, mask.size.height);

  LTProgram *program = [[[self class] programFactory] programWithVertexSource:[LTMixerVsh source]
                                                               fragmentSource:[LTMixerFsh source]];
  LTQuadDrawer *drawer = [[LTQuadDrawer alloc] initWithProgram:program sourceTexture:front];
  if (self = [super initWithDrawer:drawer sourceTexture:back
                 auxiliaryTextures:@{[LTMixerFsh maskTexture]: mask,
                                     [LTMixerFsh frontTexture]: front} andOutput:output]) {
    self.maskMatrix = GLKMatrix3Identity;
    self.maskMode = maskMode;
    self[[LTMixerFsh useLastFragColor]] = @(back == output);
    [self resetInputModel];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTQuadMixerProcessor, blendMode),
      @instanceKeypath(LTQuadMixerProcessor, frontOpacity),
      @instanceKeypath(LTQuadMixerProcessor, frontQuad),
    ]]; 
  });

  return properties;
}

- (LTBlendMode)defaultBlendMode {
  return LTBlendModeNormal;
}

- (LTQuad *)defaultFrontQuad {
  return [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBlendMode:(LTBlendMode)blendMode {
  _blendMode = blendMode;
  self[[LTMixerFsh blendMode]] = @(blendMode);
}

- (void)setFrontQuad:(LTQuad *)frontQuad {
  _frontQuad = frontQuad;
  GLKMatrix3 matrix = LTInvertedTextureMatrix3ForQuad(frontQuad, self.outputSize);
  self.frontMatrix = matrix;
  if (self.maskMode == LTMixerMaskModeFront) {
    self.maskMatrix = matrix;
  }
}

LTPropertyWithoutSetter(CGFloat, frontOpacity, FrontOpacity, 0, 1, 1);
- (void)setFrontOpacity:(CGFloat)frontOpacity {
  [self _verifyAndSetFrontOpacity:frontOpacity];
  self[[LTMixerFsh opacity]] = @(frontOpacity);
}

- (void)setFrontMatrix:(GLKMatrix3)frontMatrix {
  _frontMatrix = frontMatrix;
  self[[LTMixerVsh frontMatrix]] = $(frontMatrix);
}

- (void)setMaskMatrix:(GLKMatrix3)maskMatrix {
  _maskMatrix = maskMatrix;
  self[[LTMixerVsh maskMatrix]] = $(maskMatrix);
}

@end
