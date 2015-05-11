// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularPatchProcessor.h"

#import <numeric>

#import "LTCircularMeshModel.h"
#import "LTTexture+Factory.h"

@interface LTCircularPatchProcessor ()

/// Circular patch drawer.
@property (strong, nonatomic) LTCircularPatchDrawer *drawer;

@end

@implementation LTCircularPatchProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTParameterAssert(input);
  LTParameterAssert(output);
  LTParameterAssert(input.size == output.size);
  
  LTCircularPatchDrawer *drawer =
      [[LTCircularPatchDrawer alloc] initWithProgramFactory:[[self class] programFactory]
                                              sourceTexture:input];
  return [super initWithDrawer:drawer sourceTexture:input auxiliaryTextures:nil andOutput:output];
}

#pragma mark -
#pragma mark Process
#pragma mark -

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  [self updateDrawerColors];

  [self.inputTexture executeAndPreserveParameters:^{
    self.inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    self.inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;

    CGPoint sourceCenter = self.circularPatchMode != LTCircularPatchModeHeal ?
        self.sourceCenter : self.targetCenter;
    [self.drawer drawRect:[self rectFromCenter:self.targetCenter] inFramebuffer:placement.targetFbo
                 fromRect:[self rectFromCenter:sourceCenter]];
  }];
}

- (CGRect)rectFromCenter:(CGPoint)center {
  return CGRectCenteredAt(center, CGSizeMakeUniform(self.radius * 2));
}

#pragma mark -
#pragma mark Colors
#pragma mark -

- (void)updateDrawerColors {
  LTVector4s membraneColors(self.model.numberOfVertices);
  [self updateMembraneColors:membraneColors];
  self.drawer.membraneColors = membraneColors;
}

- (void)updateMembraneColors:(LTVector4s &)membraneColors {
  if (self.circularPatchMode == LTCircularPatchModeClone) {
    [self updateCloneMembraneColors:membraneColors];
  } else {
    [self updateMembraneBoundaryColors:membraneColors];
    [self updateMembraneInternalColors:membraneColors];
    [self smoothMembraneColors:membraneColors];
  }
  [self updateMembraneColorsAlpha:membraneColors];
}

- (void)updateMembraneBoundaryColors:(LTVector4s &)membraneColors {
  LTVector2s boundaryVertices = self.model.boundaryVertices;

  switch (self.circularPatchMode) {
    case LTCircularPatchModePatch:
      [self updatePatchMembraneColors:membraneColors forBoundaryVertices:boundaryVertices];
      break;
    case LTCircularPatchModeHeal:
      [self updateHealMembraneColors:membraneColors forBoundaryVertices:boundaryVertices];
      break;
    case LTCircularPatchModeClone:
      LTAssert(NO, @"Clone mode should not update membrane");
  }
}

- (void)updatePatchMembraneColors:(LTVector4s &)membraneColors
              forBoundaryVertices:(const LTVector2s &)boundaryVertices {
  LTVector4s boundaryTargetVerticesColor =
      [self colorUsingVertices:boundaryVertices center:self.targetCenter];
  LTVector4s boundarySourceVerticesColor =
      [self colorUsingVerticesWithRotationAndFlip:boundaryVertices center:self.sourceCenter];
  for (LTVector4s::size_type index = 0; index < boundaryVertices.size(); ++index) {
    membraneColors[self.model.firstBoundaryVertexIndex + index] =
        boundaryTargetVerticesColor[index] - boundarySourceVerticesColor[index];
  }
}

- (void)updateHealMembraneColors:(LTVector4s &)membraneColors
             forBoundaryVertices:(const LTVector2s &)boundaryVertices {
  LTVector4s boundaryTargetVerticesColor =
      [self colorUsingVertices:boundaryVertices center:self.targetCenter];
  for (LTVector4s::size_type index = 0; index < boundaryVertices.size(); ++index) {
    membraneColors[self.model.firstBoundaryVertexIndex + index] =
        boundaryTargetVerticesColor[index];
  }
}

- (void)updateCloneMembraneColors:(LTVector4s &)membraneColors {
  std::fill(membraneColors.begin(), membraneColors.end(), LTVector4(0, 0, 0, 1));
}

- (void)updateMembraneInternalColors:(LTVector4s &)membraneColors {
  LTAssert(self.model.numberOfVertexLevels >= 2);

  for (NSUInteger level = self.model.numberOfVertexLevels - 2; level > 0; --level) {
    // Each parent is the average of its childs.
    NSUInteger numVerticesInCurrentLevel = [self.model numOfVerticesInLevel:level];
    NSUInteger offsetOfCurrentLevel = [self.model firstVertexIndex:level];
    NSUInteger offsetOfUpperLevel = [self.model firstVertexIndex:level + 1];
    
    for (NSUInteger i = 0; i < numVerticesInCurrentLevel; ++i) {
      LTVector4 leftParent = membraneColors[offsetOfUpperLevel + i * 2];
      LTVector4 centerParent = membraneColors[offsetOfUpperLevel + i * 2 + 1];
      LTVector4 rightParent = (i != numVerticesInCurrentLevel - 1) ?
          membraneColors[offsetOfUpperLevel + i * 2 + 2] : membraneColors[offsetOfUpperLevel];
      membraneColors[offsetOfCurrentLevel + i] = (leftParent + centerParent + rightParent) / 3;
    }
  }
}

/// How many times an averaging pass (on each separate level) should be conducted.
static const NSUInteger kInLevelAveragingCount = 5;

// Smoothes vertices colors by averaging them on the same level.
- (void)smoothMembraneColors:(LTVector4s &)membraneColors {
  LTAssert(self.model.numberOfVertexLevels >= 2);

  for (NSUInteger level = self.model.numberOfVertexLevels - 2; level > 0; --level) {
    NSUInteger numVerticesInCurrentLevel = [self.model numOfVerticesInLevel:level];
    NSUInteger offsetOfCurrentLevel = [self.model firstVertexIndex:level];
    
    for (NSUInteger j = 0; j < kInLevelAveragingCount; ++j) {
      LTVector4s averagedColor(numVerticesInCurrentLevel);
      for (NSUInteger i = 0; i < numVerticesInCurrentLevel; ++i) {
        NSUInteger currentIndex = offsetOfCurrentLevel + i;
        
        LTVector4 left = i > 0 ? membraneColors[currentIndex - 1] :
            membraneColors[offsetOfCurrentLevel + numVerticesInCurrentLevel - 1];
        LTVector4 ego = membraneColors[currentIndex];
        LTVector4 right = offsetOfCurrentLevel < numVerticesInCurrentLevel - 1 ?
            membraneColors[currentIndex + 1] : membraneColors[0];
        averagedColor[i] = (left + ego + right) / 3;
      }
      std::copy(averagedColor.begin(), averagedColor.end(), &membraneColors[offsetOfCurrentLevel]);
    }
  }
  
  // Level 0 (root) color (mean of its rootNodeRank children).
  membraneColors[0] = LTVector4(0, 0, 0, 1);
  NSUInteger numVerticesInLevel1 = [self.model numOfVerticesInLevel:1];
  LTAssert(numVerticesInLevel1);
  NSUInteger offsetOfLevel1 = [self.model firstVertexIndex:1];
  membraneColors[0] = std::accumulate(membraneColors.begin() + offsetOfLevel1,
                                      membraneColors.begin() + offsetOfLevel1 + numVerticesInLevel1,
                                      LTVector4(0, 0, 0, 1)) / numVerticesInLevel1;

  for (LTVector4 &color : membraneColors) {
    color.a() = 1;
  }
}

- (LTVector4s)colorUsingVertices:(const LTVector2s &)vertices center:(CGPoint)center {
  CGPoints verticesAsPoints(vertices.size());
  for (CGPoints::size_type index = 0; index < vertices.size(); ++index) {
    verticesAsPoints[index] = center + (CGPoint)vertices[index] * self.radius;
  }
  return [self.inputTexture pixelValues:verticesAsPoints];
}

- (LTVector4s)colorUsingVerticesWithRotationAndFlip:(const LTVector2s &)vertices
                                             center:(CGPoint)center {
  CGPoints verticesAsPoints(vertices.size());
  CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(center.x, center.y);
  CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(-self.rotation);
  CGAffineTransform flipTransform = CGAffineTransformMakeScale(self.flip ? -1 : 1, 1);
  CGAffineTransform rotationAroundPointTransform =
      CGAffineTransformConcat(CGAffineTransformConcat(
      CGAffineTransformInvert(translateTransform),
      CGAffineTransformConcat(flipTransform, rotationTransform)), translateTransform);

  for (CGPoints::size_type index = 0; index < vertices.size(); ++index) {
    CGPoint vertex = center + (CGPoint)vertices[index] * self.radius;
    verticesAsPoints[index] = CGPointApplyAffineTransform(vertex, rotationAroundPointTransform);
  }
  return [self.inputTexture pixelValues:verticesAsPoints];
}

// All vertices above this level are constrained to have alpha = 1.
static const CGFloat kMaxLevelOfNonOpaqueVertex = 6;

// Alpha for boundary vertices.
static const CGFloat kBoundaryAlpha = 0.1;

- (void)updateMembraneColorsAlpha:(LTVector4s &)membraneColors {
  CGFloat featheringNonOpaqueVertex =
      kMaxLevelOfNonOpaqueVertex * (1 - self.featheringAlpha) + self.featheringAlpha;

  for (NSUInteger level = self.model.numberOfVertexLevels - 1; level > 0; --level) {
    CGFloat t = (level - featheringNonOpaqueVertex) /
        (self.model.numberOfVertexLevels - 1 - featheringNonOpaqueVertex);
    t = 1 - std::clamp(t, 0, 1);
    CGFloat alpha = 3 * std::pow(t, 2) - 2 * std::pow(t, 3);
    alpha = alpha * (1 - kBoundaryAlpha) + kBoundaryAlpha;
    
    NSUInteger startOfCurrentLevel = [self.model firstVertexIndex:level];
    NSUInteger verticesInLevel = [self.model numOfVerticesInLevel:level];

    std::for_each(std::begin(membraneColors) + startOfCurrentLevel,
                  std::begin(membraneColors) + startOfCurrentLevel + verticesInLevel,
                  [alpha](LTVector4 &color) {
                    color.a() = alpha;
                  });
  }
  
  // Root node.
  membraneColors[0].a() = 1;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (void)setBestSourceCenterForCenters:(const CGPoints &)sourceCenters {
  LTParameterAssert(sourceCenters.size());

  LTVector2s boundaryVertices = self.model.boundaryVertices;
  LTVector4s boundaryTargetColors =
      [self colorUsingVertices:boundaryVertices center:self.targetCenter];

  CGFloat minError = CGFLOAT_MAX;
  NSUInteger minErrorIndex = NSNotFound;
  for (CGPoints::size_type i = 0; i < sourceCenters.size(); ++i) {
    LTVector4s boundarySourceColors =
        [self colorUsingVerticesWithRotationAndFlip:boundaryVertices center:sourceCenters[i]];
    CGFloat error = [self boundaryErrorForBoundarySourceColors:boundarySourceColors
                                          boundaryTargetColors:boundaryTargetColors];
    if (error < minError) {
      minError = error;
      minErrorIndex = i;
    }
  }

  LTAssert(minErrorIndex != NSNotFound);
  self.sourceCenter = sourceCenters[minErrorIndex];
}

- (CGFloat)boundaryErrorForBoundarySourceColors:(const LTVector4s &)boundarySourceColors
                           boundaryTargetColors:(const LTVector4s &)boundaryTargetColors {
  CGFloat error = 0;
  for (LTVector4s::size_type index = 0; index < boundaryTargetColors.size(); ++index) {
    LTVector4 colorDiff = boundaryTargetColors[index] - boundarySourceColors[index];
    error += (colorDiff.rgb()).length();
  }
  return error / boundaryTargetColors.size();
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, radius, Radius, 0, CGFLOAT_MAX, 0);
LTProperty(CGFloat, featheringAlpha, FeatheringAlpha, 0, 1, 0);
LTPropertyProxy(CGFloat, alpha, Alpha, self.drawer, alpha, Alpha);
LTPropertyProxy(CGFloat, smoothingAlpha, SmoothingAlpha, self.drawer, smoothingAlpha,
                SmoothingAlpha);
LTPropertyProxy(CGFloat, rotation, Rotation, self.drawer, rotation, Rotation);

- (BOOL)flip {
  return self.drawer.flip;
}

- (void)setFlip:(BOOL)flip {
  self.drawer.flip = flip;
}

- (LTCircularPatchMode)circularPatchMode {
  return self.drawer.circularPatchMode;
}

- (void)setCircularPatchMode:(LTCircularPatchMode)circularPatchMode {
  self.drawer.circularPatchMode = circularPatchMode;
}

- (LTCircularMeshModel *)model {
  return self.drawer.circularMeshModel;
}

@end
