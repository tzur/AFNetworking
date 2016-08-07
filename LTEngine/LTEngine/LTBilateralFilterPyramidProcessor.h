// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Block for getting the range sigma for each level in the pyramid depending on its scaling factor
/// compared to \c input size.
typedef float (^LTBilateralPyramidRangeSigmaBlock)(CGFloat scalingFactor);

/// Processor that creates a pyramid such that each level is the result of a single iteration of the
/// bilateral filter on the previous level with varying range sigmas across levels.
@interface LTBilateralFilterPyramidProcessor : LTImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an input texture, an array of output textures and a function generating range
/// sigmas per output texture according to their relative size to the input.
/// It's recommended to use \c levelsForInput: or \c levelsForInput:upToLevel: to generate the
/// output textures before calling this initializer.
///
/// @param rangeFunction a block that receives the scaling factor between \c input and the current
/// output texture and returns a scalar float that will be used as the range sigma for calculating
/// the bilateral filtered output.
- (instancetype)initWithInput:(LTTexture *)input
                      outputs:(NSArray<LTTexture *> *)outputs
                rangeFunction:(LTBilateralPyramidRangeSigmaBlock)rangeFunction
    NS_DESIGNATED_INITIALIZER;

/// Convenience initializer that uses a constant function for \c rangeFunction always returning
/// \c rangeSigma.
- (instancetype)initWithInput:(LTTexture *)input
                      outputs:(NSArray<LTTexture *> *)outputs
                   rangeSigma:(float)rangeSigma;

#pragma mark -
#pragma mark Output generation
#pragma mark -

/// Returns the highest level in the pyramid for a given \c input texture.
///
/// @return <tt>max(1, floor(log2(min(input.size))))</tt>.
+ (NSUInteger)highestLevelForInput:(LTTexture *)input;

/// Creates and returns an array of \c LTTexture objects with dyadic scaling from level \c i to
/// <tt>i + 1</tt>. The number of levels in the pyramid is the value returned by
/// \c highestLevelForInput: and the returned array does not include level 1.
+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input;

/// Creates and returns an array of \c LTTexture objects with dyadic scaling from level \c i to
/// <tt>i + 1</tt>. Level 1 represents the same size as \c input, hence the total number of textures
/// created is <tt>level - 1</tt>.
///
/// For example, for an \c input of size <tt>(15, 13)</tt> and <tt>level == 3</tt>
/// the outputs will be <tt>[(8, 7), (4, 4)]</tt>.
+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input upToLevel:(NSUInteger)level;

@end

NS_ASSUME_NONNULL_END
