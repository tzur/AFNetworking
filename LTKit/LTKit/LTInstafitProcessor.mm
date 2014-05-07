// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInstafitProcessor.h"

#import "LTMathUtils.h"
#import "LTMixerProcessor.h"
#import "LTTexture+Factory.h"

@interface LTInstafitProcessor ()

@property (strong, nonatomic) LTTexture *input;
@property (strong, nonatomic) LTTexture *mask;
@property (strong, nonatomic) LTTexture *output;

@property (strong, nonatomic) LTMixerProcessor *mixer;

@end

@implementation LTInstafitProcessor

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(output.size.width == output.size.height, @"Output texture must be a square");
  if (self = [super init]) {
    self.input = input;
    self.mask = mask;
    self.output = output;
    self.background = [self defaultBackground];
    self.scaling = 1;
  }
  return self;
}

- (LTTexture *)defaultBackground {
  return [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(255, 255, 255, 255))];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (id<LTImageProcessorOutput>)process {
  return [self.mixer process];
}

- (LTMixerProcessor *)mixer {
  if (!_mixer) {
    _mixer = [[LTMixerProcessor alloc] initWithBack:self.background front:self.input
                                               mask:self.mask output:self.output];
    _mixer.outputFillMode = LTMixerOutputFillModeTile;
    _mixer.frontRotation = self.rotation;
    _mixer.frontScaling = self.scaling;
    _mixer.frontTranslation = self.translation;
  }
  return _mixer;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBackground:(LTTexture *)background {
  if (background) {
    _background = background;
  } else {
    _background = [self defaultBackground];
  }
  self.mixer = nil;
}

- (void)setTranslation:(GLKVector2)translation {
  _translation = translation;
  self.mixer.frontTranslation = _translation;
}

- (void)setScaling:(float)scaling {
  _scaling = scaling;
  self.mixer.frontScaling = _scaling;
}

- (void)setRotation:(float)rotation {
  _rotation = rotation;
  self.mixer.frontRotation = _rotation;
}

#pragma mark -
#pragma mark Model values
#pragma mark -

- (void)setObject:(id __unused)obj forKeyedSubscript:(NSString __unused *)key {
}

- (id)objectForKeyedSubscript:(NSString __unused *)key {
  return nil;
}

@end
