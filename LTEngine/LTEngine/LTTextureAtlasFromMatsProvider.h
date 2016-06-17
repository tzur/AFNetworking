// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlasProvider.h"

#import <LTKit/LTUnorderedMap.h>

#import "LTPackingRectsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTextureAtlas;

/// Implenentation of \c LTUnpackedImagesCollection using a map of \c cv::Mat objects and a packing
/// rects provider.
@interface LTTextureAtlasFromMatsProvider : NSObject <LTTextureAtlasProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the class with a given map of matrices and a packing rects provider. Each matrix
/// represents an unpacked image in a given specifing string key. \c matrices map should not be
/// empty and must contain matrices of the same type. Matrices should have positive width and
/// height. Matrices type must be convertable to an \c LTGLPixelFormat. (see
/// <tt>[LTGLPixelFormat initWithMatType:]</tt> for more information).
- (instancetype)initWithMatrices:(const lt::unordered_map<NSString *, cv::Mat> &)matrices
            packingRectsProvider:(id<LTPackingRectsProvider>)packingRectsProvider
    NS_DESIGNATED_INITIALIZER;

/// Creates an \c LTTextureAtlas object using the initialized matrices map and packing rects
/// provider. The packing rects provider helps to determine the packing technique by creating the
/// atlas \c areas rects. The keys of the atlas \c areas fit the keys of the matrices map. The atlas
/// texture size is set as the minimal bounding size of the atlas \c areas. Residual areas in the
/// atlas \c texture (areas that don't have any mapped matrix upon them) will be filled with zeros.
///
/// @note Each call to this method will generate a new atlas based on the current content of the
/// matrices.
- (LTTextureAtlas *)atlas;

@end

NS_ASSUME_NONNULL_END
