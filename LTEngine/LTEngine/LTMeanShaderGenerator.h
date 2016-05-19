// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Class for generating the fragment shader source string for \c LTMeanProcessor.
@interface LTMeanShaderGenerator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a given number of textures.
///
/// @param textureCount The number of textures the generated shader should handle. Should be > 1.
- (instancetype)initWithNumberOfTextures:(NSUInteger)textureCount NS_DESIGNATED_INITIALIZER;

/// Output shader string.
@property (readonly, nonatomic) NSString *fragmentShaderSource;

/// Array of the uniform names used as keys in the auxiliary textures dictionary.
@property (readonly, nonatomic) NSArray<NSString *> *texturesUniformNames;

@end

NS_ASSUME_NONNULL_END
