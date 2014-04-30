// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMixerProcessor.h"

#import "LTCGExtensions.h"
#import "LTPassthroughProcessor.h"
#import "LTProgram.h"
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

/// Passthrough processor used to write the back texture prior to mixing.
@property (strong, nonatomic) LTPassthroughProcessor *passthroughProcessor;

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
  if (self = [super initWithProgram:[self createMixerProgram] sourceTexture:back
                  auxiliaryTextures:@{[LTMixerFsh frontTexture]: front,
                                      [LTMixerFsh maskTexture]: mask}
                          andOutput:output]) {
    self.front = front;
    self.passthroughProcessor = [self createPassthroughProcessorWithInput:back output:output];
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.frontTranslation = GLKVector2Make(0, 0);
  self.frontScaling = 1;
  self.frontRotation = 0;

  self.frontSourceRect = [LTRotatedRect rect:CGRectFromSize(self.front.size)];
  self.frontTargetRect = [self.frontSourceRect copy];
}

- (LTProgram *)createMixerProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTMixerVsh source]
                                  fragmentSource:[LTMixerFsh source]];
}

- (LTPassthroughProcessor *)createPassthroughProcessorWithInput:(LTTexture *)input
                                                         output:(LTTexture *)output {
  return [[LTPassthroughProcessor alloc] initWithInput:input output:output];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (id<LTImageProcessorOutput>)process {
  // TODO:(yaron) this can be improved by processing only the area that needs to be redrawn since
  // the last processing.
  [self.passthroughProcessor process];
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

- (void)setFrontSourceRect:(LTRotatedRect *)frontSourceRect {
  _frontSourceRect = frontSourceRect;

  GLKMatrix3 targetTextureMat = LTTextureMatrix3ForRotatedRect(frontSourceRect, self.front.size);
  self[[LTMixerVsh frontTextureMat]] = $(targetTextureMat);
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
