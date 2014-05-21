// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMixerProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRectCopyProcessor.h"
#import "LTRectMapping.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTMixerFsh.h"
#import "LTShaderStorage+LTMixerVsh.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement;

@property (strong, nonatomic) id<LTProcessingDrawer> drawer;
@property (strong, nonatomic) id<LTProcessingStrategy> strategy;

@end

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
  if (self = [super initWithProgram:[self createMixerProgram] sourceTexture:front
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

  self.frontTranslation = GLKVector2Make(0, 0);
  self.frontScaling = 1;
  self.frontRotation = 0;
}

- (LTProgram *)createMixerProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTMixerVsh source]
                                  fragmentSource:[LTMixerFsh source]];
}

- (LTRectCopyProcessor *)createBackCopyProcessorWithInput:(LTTexture *)input
                                                   output:(LTTexture *)output {
  return [[LTRectCopyProcessor alloc] initWithInput:input output:output];
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

- (void)setOutputFillMode:(LTMixerOutputFillMode)outputFillMode {
  _outputFillMode = outputFillMode;

  switch (outputFillMode) {
    case LTMixerOutputFillModeStretch:
      self.backCopyProcessor.texturingMode = LTRectCopyTexturingModeStretch;
      break;
    case LTMixerOutputFillModeTile:
      self.backCopyProcessor.texturingMode = LTRectCopyTexturingModeTile;
      break;
  }
}

- (void)setFrontTranslation:(GLKVector2)frontTranslation {
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
  // Rect of front texture with translation only.
  CGRect translated = CGRectMake(self.frontTranslation.x, self.frontTranslation.y,
                                 self.front.size.width, self.front.size.height);
  CGPoint center = CGRectCenter(translated);

  // Scale around the center of the rect.
  CGSize scaledSize = CGSizeMake(self.front.size.width * self.frontScaling,
                                 self.front.size.height * self.frontScaling);
  CGRect scaledAndTranslated = CGRectCenteredAt(center, scaledSize);

  self.frontTargetRect = [LTRotatedRect rect:scaledAndTranslated withAngle:self.frontRotation];
}

@end
