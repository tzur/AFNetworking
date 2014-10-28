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

/// Processor used to write the back texture to output prior to mixing.
@property (strong, nonatomic) LTRectCopyProcessor *backCopyProcessor;

@property (strong, nonatomic) LTQuadDrawer *quadDrawer;

/// Source quad to draw front texture from.
@property (strong, nonatomic) LTQuad *frontSourceQuad;

/// Mask mode used to mix the front and the back texture.
@property (nonatomic) LTMixerMaskMode maskMode;

/// Size of front texture to draw.
@property (nonatomic) CGSize frontSize;

/// Size of the applied mask.
@property (nonatomic) CGSize maskSize;

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
  if (self = [super initWithDrawer:drawer sourceTexture:front
                 auxiliaryTextures:@{[LTMixerFsh maskTexture]: mask} andOutput:output]) {
    self[[LTMixerVsh mask]] = $(GLKMatrix3Identity);
    self.maskMode = maskMode;
    self.frontSize = front.size;
    self.maskSize = mask.size;
    self.frontQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
    self.backCopyProcessor = [self createBackCopyProcessorWithInput:back output:output];
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.frontSourceQuad = [LTQuad quadFromRect:CGRectFromSize(self.frontSize)];
  self.frontOpacity = self.defaultFrontOpacity;
}

- (LTRectCopyProcessor *)createBackCopyProcessorWithInput:(LTTexture *)input
                                                   output:(LTTexture *)output {
  return [[LTRectCopyProcessor alloc] initWithInput:input output:output];
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
      @instanceKeypath(LTQuadMixerProcessor, fillMode),
      @instanceKeypath(LTQuadMixerProcessor, frontOpacity),
      @instanceKeypath(LTQuadMixerProcessor, frontQuad),
    ]]; 
  });

  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  // TODO:(Yaron/Rouven) this can be improved by processing only the area that needs to be redrawn
  // since the last processing.
  [self.backCopyProcessor process];
  return [super process];
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [((LTQuadDrawer *)self.drawer) drawQuad:self.frontQuad inFramebuffer:placement.targetFbo
                                 fromQuad:self.frontSourceQuad];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBlendMode:(LTBlendMode)blendMode {
  _blendMode = blendMode;
  self[[LTMixerFsh blendMode]] = @(blendMode);
}

- (void)setFillMode:(LTProcessorFillMode)fillMode {
  _fillMode = fillMode;
  self.backCopyProcessor.fillMode = fillMode;
}

- (void)setFrontQuad:(LTQuad *)frontQuad {
  _frontQuad = frontQuad;
  if (self.maskMode == LTMixerMaskModeBack) {
    self[[LTMixerVsh mask]] = $(LTTextureMatrix3ForQuad(frontQuad, self.maskSize));
  }
}

LTPropertyWithoutSetter(CGFloat, frontOpacity, FrontOpacity, 0, 1, 1);
- (void)setFrontOpacity:(CGFloat)frontOpacity {
  [self _verifyAndSetFrontOpacity:frontOpacity];
  self[[LTMixerFsh opacity]] = @(frontOpacity);
}

@end
