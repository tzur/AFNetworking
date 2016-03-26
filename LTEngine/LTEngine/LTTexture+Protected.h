// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

#import "LTTexture+Sampling.h"
#import "LTTexture+Writing.h"

NS_ASSUME_NONNULL_BEGIN

/// Sampling points inside the texture's bounds.
typedef std::vector<cv::Point2i> LTTextureSamplingPoints;

@interface LTTexture ()

/// Updates the generation ID of the texture to a new random identifier.
- (void)updateGenerationID;

/// Executes the given block while keeping the texture's \c generationID unchanged.
- (void)performWithoutUpdatingGenerationID:(LTVoidBlock)block;

/// Returns \c YES if the given rect is completely inside the texture.
- (BOOL)inTextureRect:(CGRect)rect;

/// Returns pixel sampling points in the rect [0, 0, self.size.width - 1, self.size.height - 1]
/// using symmetric boundary condition from a collection of locations that can be outside the
/// texture's bounds.
- (LTTextureSamplingPoints)samplingPointsFromLocations:(const CGPoints &)locations;

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
