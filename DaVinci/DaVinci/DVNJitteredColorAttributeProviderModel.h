// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTGPUStruct.h>

#import "DVNAttributeProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Value class representing the format of attribute data returned by \c id<DVNAttributeProvider>
/// constructed from \c DVNJitteredColorAttributeProviderModel objects. Represents the jittered
/// color of a processed quad.
LTGPUStructDeclare(DVNJitteredColorAttributeProviderStruct,
                   GLubyte, colorRed,
                   GLubyte, colorGreen,
                   GLubyte, colorBlue);

@class LTRandomState;

/// Object providing jittered color for each \c quad in the processed \c dvn::GeometryValues as a
/// attribute data. Calling \c attributeDataFromGeometryValues: on the attribute provider yields
/// \c LTAttributeData of the following form: the \c gpuStruct of the attribute data is the
/// \c DVNJitteredColorAttributeProviderStruct GPU struct. The \c data of the attribute data - per
/// quad - has the form <tt>{{color}, {color}, {color}, {color}, {color}, {color}}</tt>, \c where
/// \c color corresponds to a jittered color that is obtained from a base color, brightness jitter,
/// saturation jitter and hue jitter parameters given upon initialization in the following way:
/// Let \c x and \c x' be the brightness, hue or saturation value of the base color and of the
/// \c color, respectively. In addition, let \c <x> be the corresponding key \c brightness, \c hue
/// or \c saturation. Then every x' is drawn from a uniform distribution with support
/// <tt>[x - xJitter, x + xJitter]</tt>. All the aftermentioned sampled values are clamped to be in
/// \c [0, 1] range.
@interface DVNJitteredColorAttributeProviderModel : NSObject <DVNAttributeProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c baseColor, \c brightnessJitter, \c hueJitter, \c saturationJitter
/// and \c randomState. Jitter parameters must be in \c [0, 1] range.
- (instancetype)initWithBaseColor:(LTVector3)baseColor brightnessJitter:(CGFloat)brightnessJitter
                        hueJitter:(CGFloat)hueJitter saturationJitter:(CGFloat)saturationJitter
                      randomState:(LTRandomState *)randomState NS_DESIGNATED_INITIALIZER;

/// Base color in RGB space.
@property (readonly, nonatomic) LTVector3 baseColor;

/// Value specifying the range of the brightness jitter.
@property (readonly, nonatomic) CGFloat brightnessJitter;

/// Value specifying the range of the hue jitter.
@property (readonly, nonatomic) CGFloat hueJitter;

/// Value specifying the range of the saturation jitter.
@property (readonly, nonatomic) CGFloat saturationJitter;

/// State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
@property (readonly, nonatomic) LTRandomState *randomState;

@end

NS_ASSUME_NONNULL_END
