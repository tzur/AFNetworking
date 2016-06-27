// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

@class LT3DLUT, LT3DLUTTextureAtlas;

/// Class for producing 3D LUTs texture atlas objects from a given collection of LUTs.
@interface LT3DLUTTextureAtlasProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the class with a map of 3D LUTs with identifying string keys. \c luts should not be
/// empty.
- (instancetype)initWithLUTs:(NSDictionary<NSString *, LT3DLUT *> *)luts NS_DESIGNATED_INITIALIZER;

/// Returns a 3D LUTs texture atlas using the initialization LUTs map. The keys in the atlas \c
/// spatialDataMap match the keys in the initialization map where each spatial data descriptor
/// describes its corresponding LUT. LUTs are concatenated in horizontal fashion on the atlas \c
/// texture while residual areas (areas that don't have any mapped LUT upon them) are filled with
/// zeros.
///
/// @note Each call to this method will generate a new atlas.
- (LT3DLUTTextureAtlas *)textureAtlas;

@end

NS_ASSUME_NONNULL_END
