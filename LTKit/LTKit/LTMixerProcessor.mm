// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMixerProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTQuad.h"
#import "LTQuadMixerProcessor.h"
#import "LTRectCopyProcessor.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTMixerFsh.h"
#import "LTShaderStorage+LTMixerVsh.h"
#import "LTTexture.h"

@interface LTMixerProcessor ()

/// Internal mixer processor.
@property (strong, nonatomic) LTQuadMixerProcessor *internalProcessor;

/// Size of the front texture to draw.
@property (nonatomic) CGSize frontSize;

@end

@implementation LTMixerProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front
                        mask:(LTTexture *)mask output:(LTTexture *)output {
  return [self initWithBack:back front:front mask:mask output:output maskMode:LTMixerMaskModeFront];
}

- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front mask:(LTTexture *)mask
                      output:(LTTexture *)output maskMode:(LTMixerMaskMode)maskMode {
  if (maskMode == LTMixerMaskModeFront) {
    LTParameterAssert(front.size == mask.size, @"Front size (%g, %g) must equal mask size (%g, %g)",
                      front.size.width, front.size.height, mask.size.width, mask.size.height);
  } else {
    LTParameterAssert(back.size == mask.size, @"Back size (%g, %g) must equal mask size (%g, %g)",
                      back.size.width, back.size.height, mask.size.width, mask.size.height);
  }
  if (self = [super initWithVertexSource:[LTMixerVsh source]
                          fragmentSource:[LTMixerFsh source] sourceTexture:front
                       auxiliaryTextures:@{[LTMixerFsh maskTexture]: mask}
                               andOutput:output]) {
    self.internalProcessor =
        [[LTQuadMixerProcessor alloc] initWithBack:back front:front mask:mask output:output
                                          maskMode:maskMode];
    self.frontSize = front.size;
    [self resetInputModel];
  }
  return self;
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
      @instanceKeypath(LTMixerProcessor, blendMode),
      @instanceKeypath(LTMixerProcessor, frontTranslation),
      @instanceKeypath(LTMixerProcessor, frontScaling),
      @instanceKeypath(LTMixerProcessor, frontRotation),
      @instanceKeypath(LTMixerProcessor, frontOpacity)
    ]];
  });

  return properties;
}

- (LTBlendMode)defaultBlendMode {
  return LTBlendModeNormal;
}

- (CGPoint)defaultFrontTranslation {
  return CGPointZero;
}

- (float)defaultFrontScaling {
  return 1;
}

- (float)defaultFrontRotation {
  return 0;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self.internalProcessor processToFramebufferWithSize:size outputRect:rect];
}

- (void)process {
  [self.internalProcessor process];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTBlendMode)blendMode {
  return self.internalProcessor.blendMode;
}

- (void)setBlendMode:(LTBlendMode)blendMode {
  self.internalProcessor.blendMode = blendMode;
}

- (void)setFrontTranslation:(CGPoint)frontTranslation {
  _frontTranslation = frontTranslation;
  [self updateFrontTargetRect];
}

- (void)setFrontScaling:(float)frontScaling {
  _frontScaling = frontScaling;
  [self updateFrontTargetRect];
}

- (void)setFrontRotation:(float)frontRotation {
  _frontRotation = frontRotation;
  [self updateFrontTargetRect];
}

- (void)updateFrontTargetRect {
  LTQuad *frontQuad;
  if (self.frontScaling) {
    LTRotatedRect *frontTargetRect = [LTRotatedRect rectWithSize:self.frontSize
                                                     translation:self.frontTranslation
                                                         scaling:self.frontScaling
                                                     andRotation:self.frontRotation];
    frontQuad = [LTQuad quadFromRotatedRect:frontTargetRect];
  }
  self.internalProcessor.frontQuad = frontQuad;
}

LTPropertyProxy(CGFloat, frontOpacity, FrontOpacity, self.internalProcessor);

@end
