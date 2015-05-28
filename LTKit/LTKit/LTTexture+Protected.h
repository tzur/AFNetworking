// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTexture ()

/// Updates the generation ID of the texture to a new random identifier.
- (void)updateGenerationID;

/// Executes the given block while keeping the texture's \c generationID unchanged.
- (void)performWithoutUpdatingGenerationID:(LTVoidBlock)block;

/// Executes the given block while keeping the texture's \c fillColor unchanged.
- (void)performWithoutUpdatingFillColor:(LTVoidBlock)block;

/// Returns \c YES if the given rect is completely inside the texture.
- (BOOL)inTextureRect:(CGRect)rect;

/// Type of \c cv::Mat according to the current \c precision of the texture.
@property (readonly, nonatomic) int matType;

/// Maximal (coarsest) mipmap level to be selected in this texture. For non-mipmap textures, this
/// value is \c 0.
@property (readwrite, nonatomic) GLint maxMipmapLevel;

/// Returns the color the entire texture is filled with, or \c LTVector4Null in case it is uncertain
/// that the texture is filled with a single color. This property is updated when the texture is
/// cleared using \c clearWithColor, and set to \c LTVector4Null whenever the texture is updated by
/// any other method.
@property (readwrite, nonatomic) LTVector4 fillColor;

/// Current generation ID of this texture. The generation ID changes whenever the texture is
/// modified, and is copied when a texture is cloned. This can be used as an efficient way to check
/// if a texture has changed or if two textures have the same content.
///
/// @note While two textures having equal \c generationID implies that they have the same
/// content, the other direction is not necessarily true as two textures can have the same content
/// with different \c generationID.
@property (readwrite, strong, nonatomic) NSString *generationID;

@end

NS_ASSUME_NONNULL_END
