// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@class LTGLPixelFormat;

/// Metadata of an \c LTTexture.
@interface LTTextureMetadata : MTLModel <MTLJSONSerializing>

/// @see \c LTTexture.size.
@property (readonly, nonatomic) CGSize size;

/// @see \c LTTexture.pixelFormat.
@property (readonly, nonatomic) LTGLPixelFormat *pixelFormat;

/// @see \c LTTexture.maxMipmapLevel.
@property (readonly, nonatomic) GLint maxMipmapLevel;

/// @see \c LTTexture.usingAlphaChannel.
@property (readonly, nonatomic) BOOL usingAlphaChannel;

#pragma mark -
#pragma mark Rendering Parameters
#pragma mark -

/// @see \c LTTexture.minFilterInterpolation.
@property (readonly, nonatomic) LTTextureInterpolation minFilterInterpolation;

/// @see \c LTTexture.magFilterInterpolation.
@property (readonly, nonatomic) LTTextureInterpolation magFilterInterpolation;

/// @see \c LTTexture.wrap.
@property (readonly, nonatomic) LTTextureWrap wrap;

#pragma mark -
#pragma mark State
#pragma mark -

/// @see \c LTTexture.generationID.
@property (readonly, nonatomic) NSString *generationID;

/// @see \c LTTexture.fillColor.
@property (readonly, nonatomic) LTVector4 fillColor;

@end

/// Category adding methods to extract metadata from a texture and create a texture with the given
/// metadata.
@interface LTTexture (LTTextureMetadata)

/// Creates an empty texture with the given metadata, excluding the \c fillColor and \c generationID
/// properties.
+ (instancetype)textureWithMetadata:(LTTextureMetadata *)metadata;

/// Returns the texture's metadata.
- (LTTextureMetadata *)metadata;

@end

NS_ASSUME_NONNULL_END
