// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

@class LTTextureAtlas;

/// Protocol for producing texture atlas objects.
@protocol LTTextureAtlasProvider <NSObject>

/// Returns an \c LTTextureAtlas object;
- (LTTextureAtlas *)atlas;

@end

NS_ASSUME_NONNULL_END
