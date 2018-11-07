// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import <LTKit/LTUnorderedMap.h>

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Class for describing a collection of images packed in a single texture, the atlas.
@interface LTTextureAtlas : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the class with a given atlas \c texture and \c areas. \c areas is a non empty
/// dictionary mapping identifying strings to their corresponding \c std::vector<CGRect>. Each rect
/// describes the area of its unpacked image upon \c texture. All rects must be contained inside the
/// \c texture size rect and should have positive widths and heights.
- (instancetype)initWithAtlasTexture:(LTTexture *)texture
                          imageAreas:(const lt::unordered_map<NSString *, CGRect> &)areas
    NS_DESIGNATED_INITIALIZER;

/// Packing texture that is composed from a collection of images upon it.
@property (readonly, nonatomic) LTTexture *texture;

/// Dictionary mapping identifying strings to their corresponding std::vector<CGRect>. Each rect
/// describes the area of its unpacked image upon the \c texture.
@property (readonly, nonatomic) lt::unordered_map<NSString *, CGRect> areas;

@end

NS_ASSUME_NONNULL_END
