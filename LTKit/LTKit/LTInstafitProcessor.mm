// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInstafitProcessor.h"

#import "LTImageBorderProcessor.h"
#import "LTMathUtils.h"
#import "LTMixerProcessor.h"
#import "LTTexture+Factory.h"

@interface LTInstafitProcessor ()

/// Input texture, used to initialize the border processor.
@property (strong, nonatomic) LTTexture *input;

/// Mixer input texture, used as output of the border processor and input of the mixer processor.
@property (strong, nonatomic) LTTexture *mixerInput;

/// Texture of the size of mixerInput, which is required by the mixer.
/// @note right now masking functionality is not used in this feature.
@property (strong, nonatomic) LTTexture *mask;

/// Output texture, holds the combined result of border and mixer processors.
@property (strong, nonatomic) LTTexture *output;

/// Border processor adds a border around \c input before processing in \c mixer.
@property (strong, nonatomic) LTImageBorderProcessor *borderProcessor;

/// Mixer processor places \c mixerInput on the \c background texture.
@property (strong, nonatomic) LTMixerProcessor *mixer;

@end

@implementation LTInstafitProcessor

@synthesize background = _background;

- (instancetype)initWithInput:(LTTexture *)input contentMaxDimension:(CGFloat)dimension
                       output:(LTTexture *)output {
  LTParameterAssert(output.size.width == output.size.height, @"Output texture must be a square");
  if (self = [super init]) {
    [self configureTexturesWithInput:input maxDimension:dimension output:output];
    [self resetInputModel];
  }
  return self;
}

- (void)configureTexturesWithInput:(LTTexture *)input maxDimension:(CGFloat)dimension
                            output:(LTTexture *)output {
  self.input = input;
  self.mixerInput = [self createMixerInput:input withMaxDimension:dimension];
  self.mask = [LTTexture textureWithPropertiesOf:self.mixerInput];
  [self.mask clearWithColor:LTVector4One];
  self.output = output;
}

- (LTTexture *)defaultBackground {
  return [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(255, 255, 255, 255))];
}

- (LTProcessorFillMode)defaultFillMode {
  return LTProcessorFillModeTile;
}

- (CGPoint)defaultTranslation {
  return CGPointZero;
}

- (CGFloat)defaultScaling {
  return 1;
}

- (CGFloat)defaultRotation {
  return 0;
}

- (LTTexture *)createMixerInput:(LTTexture *)input withMaxDimension:(CGFloat)dimension {
  CGSize size = CGScaleDownToDimension(input.size, dimension);
  return [LTTexture byteRGBATextureWithSize:size];
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTInstafitProcessor, fillMode),
      @instanceKeypath(LTInstafitProcessor, translation),
      @instanceKeypath(LTInstafitProcessor, scaling),
      @instanceKeypath(LTInstafitProcessor, rotation),
      @instanceKeypath(LTInstafitProcessor, background),
      @instanceKeypath(LTInstafitProcessor, frameColor),
      @instanceKeypath(LTInstafitProcessor, frameWidth)
    ]];
  });

  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self preprocess];
  [self.borderProcessor process];
  [self.mixer process];
}

- (LTMixerProcessor *)mixer {
  if (!_mixer) {
    _mixer = [[LTMixerProcessor alloc] initWithBack:self.background front:self.mixerInput
                                               mask:self.mask output:self.output];
    _mixer.fillMode = self.fillMode;
    _mixer.frontRotation = self.rotation;
    _mixer.frontScaling = self.scaling;
    _mixer.frontTranslation = self.translation;
  }
  return _mixer;
}

- (LTImageBorderProcessor *)borderProcessor {
  if (!_borderProcessor) {
    _borderProcessor =
       [[LTImageBorderProcessor alloc] initWithInput:self.input output:self.mixerInput];
  }
  return _borderProcessor;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTTexture *)background {
  if (!_background) {
    _background = [self defaultBackground];
  }
  return _background;
}

- (void)setBackground:(LTTexture *)background {
  if (background) {
    _background = background;
  } else {
    _background = [self defaultBackground];
  }
  self.mixer = nil;
}

// The getter in the following three properties is intentionally not implemented by accessing the
// corresponding mixer properties. The rationale is to retain these values unchanged upon creation
// of the new mixer object, which happens when new background is passed.

- (void)setTranslation:(CGPoint)translation {
  _translation = translation;
  self.mixer.frontTranslation = translation;
}

- (void)setScaling:(CGFloat)scaling {
  _scaling = scaling;
  self.mixer.frontScaling = scaling;
}

- (void)setRotation:(CGFloat)rotation {
  _rotation = rotation;
  self.mixer.frontRotation = rotation;
}

LTPropertyWithoutSetter(LTVector3, frameColor, FrameColor, LTVector3Zero, LTVector3One,
                        LTVector3Zero);
- (void)setFrameColor:(LTVector3)frameColor {
  [self _verifyAndSetFrameColor:frameColor];
  self.borderProcessor.outerFrameColor = frameColor;
}

LTPropertyWithoutSetter(CGFloat, frameWidth, FrameWidth, 0, 1, 0);
- (void)setFrameWidth:(CGFloat)frameWidth {
  static const CGFloat kFrameScalingFactor = 0.25;
  [self _verifyAndSetFrameWidth:frameWidth];
  self.borderProcessor.outerFrameWidth = frameWidth * kFrameScalingFactor *
      self.borderProcessor.maxOuterFrameWidth;
}
@end
