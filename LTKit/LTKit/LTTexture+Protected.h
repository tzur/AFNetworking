// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

@interface LTTexture ()

/// Increases the generation ID of the texture.
- (void)increaseGenerationID;

/// Executes the given block while ignoring all automatic updates to the texture's \c fillColor.
- (void)performWithoutUpdatingFillColor:(LTVoidBlock)block;

/// Returns \c YES if the given rect is completely inside the texture.
- (BOOL)inTextureRect:(CGRect)rect;

/// Type of \c cv::Mat according to the current \c precision of the texture.
@property (readonly, nonatomic) int matType;

/// Returns the color the entire texture is filled with, or \c LTVector4Null in case it is uncertain
/// that the texture is filled with a single color. This property is updated when the texture is
/// cleared using \c clearWithColor, and set to \c LTVector4Null whenever the texture is updated by
/// any other method.
@property (readwrite, nonatomic) LTVector4 fillColor;

@end
