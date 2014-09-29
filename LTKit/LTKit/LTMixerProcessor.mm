// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMixerProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRectCopyProcessor.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTMixerFsh.h"
#import "LTShaderStorage+LTMixerVsh.h"
#import "LTTexture.h"

@interface LTMixerProcessor ()

/// Processor used to write the back texture to output prior to mixing.
@property (strong, nonatomic) LTRectCopyProcessor *backCopyProcessor;

/// Source rect to draw front texture from.
@property (strong, nonatomic) LTRotatedRect *frontSourceRect;

/// Target rect to draw front texture to.
@property (strong, nonatomic) LTRotatedRect *frontTargetRect;

/// Front texture to draw.
@property (strong, nonatomic) LTTexture *front;

@end

@implementation LTMixerProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front
                        mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(front.size == mask.size, @"Front size (%g, %g) must equal mask size (%g, %g)",
                    front.size.width, front.size.height, mask.size.width, mask.size.height);
  if (self = [super initWithVertexSource:[LTMixerVsh source]
                          fragmentSource:[LTMixerFsh source] sourceTexture:front
                       auxiliaryTextures:@{[LTMixerFsh maskTexture]: mask}
                               andOutput:output]) {
    self.front = front;
    self.backCopyProcessor = [self createBackCopyProcessorWithInput:back output:output];
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.frontSourceRect = [LTRotatedRect rect:CGRectFromSize(self.front.size)];

  self.frontTranslation = CGPointZero;
  self.frontScaling = 1;
  self.frontRotation = 0;
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
      @instanceKeypath(LTMixerProcessor, blendMode),
      @instanceKeypath(LTMixerProcessor, fillMode),
      @instanceKeypath(LTMixerProcessor, frontTranslation),
      @instanceKeypath(LTMixerProcessor, frontScaling),
      @instanceKeypath(LTMixerProcessor, frontRotation),
      @instanceKeypath(LTMixerProcessor, frontOpacity)
    ]];
  });

  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  // TODO:(yaron) this can be improved by processing only the area that needs to be redrawn since
  // the last processing.
  [self.backCopyProcessor process];
  return [super process];
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [self.drawer drawRotatedRect:self.frontTargetRect inFramebuffer:placement.targetFbo
               fromRotatedRect:self.frontSourceRect];
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
  self.frontTargetRect = [LTRotatedRect rectWithSize:self.front.size
                                         translation:self.frontTranslation
                                             scaling:self.frontScaling
                                         andRotation:self.frontRotation];
}

LTPropertyWithoutSetter(CGFloat, frontOpacity, FrontOpacity, 0, 1, 1);
- (void)setFrontOpacity:(CGFloat)frontOpacity {
  [self _verifyAndSetFrontOpacity:frontOpacity];
  self[[LTMixerFsh opacity]] = @(frontOpacity);
}

@end
