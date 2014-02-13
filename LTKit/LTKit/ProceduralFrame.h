// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// TODO
@interface ProceduralFrame : LTOneShotImageProcessor

/// Initializes a dual frame processor with an output texture.
- (instancetype)initWithNoise:(LTTexture *)noise output:(LTTexture *)output;

/// Percent of the
@property (nonatomic) CGFloat width;

///
@property (nonatomic) CGFloat spread;

///
@property (nonatomic) CGFloat corner;

///
@property (nonatomic) GLKVector3 noiseChannelMixer;

///
@property (nonatomic) CGFloat noiseAmplitude;

///
@property (nonatomic) CGFloat contrastScalingBoost;

///
@property (nonatomic) GLKVector3 wideColor;

@end
