// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTTextureDrawer.h"

#import "LTGPUStruct.h"

@protocol LTProgramFactory;

@class LTCircularMeshModel;

/// Types of circular patch modes.
typedef NS_ENUM(NSUInteger, LTCircularPatchMode) {
  /// Patches a given target circular patch with a source circular patch.
  LTCircularPatchModePatch = 0,
  /// Heals a given target circular patch.
  LTCircularPatchModeHeal,
  /// Copies pixels from a source circular patch to a target circular patch.
  LTCircularPatchModeClone
};

/// Class for drawing a circular patch from source to target. There are 3 different modes for
/// drawing the circular patch - patch (source to target with smoothing membrane), heal (using
/// smoothing membrane) and clone (source to target). Before drawing, \c membraneColors must be set.
@interface LTCircularPatchDrawer : LTTextureDrawer

/// Initializes a new circular patch drawer using \c programFactory and \c sourceTexture.
- (instancetype)initWithProgramFactory:(id<LTProgramFactory>)programFactory
                         sourceTexture:(LTTexture *)sourceTexture;

/// Updates array describing circular patch membrane color for each vertex. The given
/// \c membranceColors must have the same number of elements as the number of vertices.
- (void)setMembraneColors:(const LTVector4s &)membraneColors;

/// Circular mesh model holding the normalized vertices positions.
@property (readonly, nonatomic) LTCircularMeshModel *circularMeshModel;

/// Circular patch mode. \c LTCircularPatchModePatch is the default mode.
@property (nonatomic) LTCircularPatchMode circularPatchMode;

/// Clockwise rotation in radians of the source patch.
@property (nonatomic) CGFloat rotation;
LTPropertyDeclare(CGFloat, rotation, Rotation);

/// Blends source and target patches using \c alpha in the range of [0, 1]. Default value is \c 1,
/// which means fully blended.
@property (nonatomic) CGFloat alpha;
LTPropertyDeclare(CGFloat, alpha, Alpha);

@end
