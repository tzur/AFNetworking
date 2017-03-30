// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Repository of weakly-held textures, retrieveable by their current \c generationID.
@interface LTTextureRepository : NSObject

/// Adds a weak pointer to the given \c texture to the repository.
- (void)addTexture:(LTTexture *)texture;

/// Returns a texture with the matching \c generationID if there is one in the repository, or \c nil
/// otherwise.
- (nullable LTTexture *)textureWithGenerationID:(NSString *)generationID;

@end

NS_ASSUME_NONNULL_END
