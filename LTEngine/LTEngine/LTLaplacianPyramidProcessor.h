// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTImageProcessor.h"

@class LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Builds the laplacian pyramid representation of a given image.
@interface LTLaplacianPyramidProcessor : LTImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an input texture and uses \c levelsForInput: to generate the output textures.
- (instancetype)initWithInputTexture:(LTTexture *)input;

/// Initializes with an input texture and a set of outputs. It's recommended to use
/// \c levelsForInput: or \c levelsForInput:upToLevel: to generate the output textures
/// before calling this initializer.
///
/// @note The outputs textures do not have to be a full pyramid and higher (smaller) levels can be
/// ommited from the \c outputs array if they are not required.
- (instancetype)initWithInputTexture:(LTTexture *)input
                  outputPyramidArray:(NSArray<LTTexture *> *)outputs NS_DESIGNATED_INITIALIZER;

#pragma mark -
#pragma mark Output generation
#pragma mark -

/// Returns the highest level in the pyramid for a given \c input texture.
///
/// @return <tt>max(1, floor(log2(min(input.size))))</tt>.
+ (NSUInteger)highestLevelForInput:(LTTexture *)input;

/// Creates and returns an array of \c LTTexture objects with dyadic scaling from level \c i to
/// <tt>i + 1</tt>, where the number of levels is the value returned by \c highestLevelForInput:.
/// The textures will be created with float precision and same number of channels as the input
/// texture.
///
/// For example, for an RGBA8U input of size <tt>(15, 13)</tt> the outputs will be
/// <tt>RGBA16HF [(15, 13), (8, 7), (4, 4)]</tt>.
///
/// @note This method's return value includes a texture with the same size as \c input.
+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input;

/// Creates and returns an array of \c LTTexture objects with dyadic scaling from level \c i to
/// <tt>i + 1</tt>. Starting from level 1 being the same size as the original texture, the total
/// number of levels is \c level. The textures will be created with float precision and same number
/// of channels as the input texture and the same min/mag filter as the input texture.
///
/// For example, for an RGBA8U input of size <tt>(15, 13)</tt> and <tt>level == 2</tt>
/// the outputs will be <tt>RGBA16HF [(15, 13), (8, 7)]</tt>.
+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input upToLevel:(NSUInteger)level;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Laplacian pyramid representation of the \c input texture.
///
/// @note The array \c outputLaplacianPyramid will be the array given in the designated initializer.
/// If a convenience initializer is used, the array created in it will be assigned to
/// \c outputLaplacianPyramid.
@property (readonly, nonatomic) NSArray<LTTexture *> *outputLaplacianPyramid;

@end

NS_ASSUME_NONNULL_END
