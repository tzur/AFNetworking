// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularMeshModel.h"

static LTVector2 LTVector2PolarMake(CGPoint offset, CGFloat r, CGFloat theta) {
  return LTVector2(offset.x + r * std::cos(theta), offset.y + r * std::sin(theta));
}

@implementation LTCircularMeshModel

/// Number of vertex levels in the circular mesh.
static const NSUInteger kNumberOfVertexLevels = 9;

/// The rank of the central vertex of the circular mesh. Currently, hold this fixed as the mesh is
/// not flexible enough to deal with a different value.
static const NSUInteger kRootNodeRank = 8;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self createCircularMesh];
  }
  return self;
}

#pragma mark -
#pragma mark Mesh
#pragma mark -

- (void)createCircularMesh {
  _vertices.clear();
  _indices.clear();
  
  // Create root node (level 0).
  _vertices.push_back(LTVector2::zeros());
  
  // Create sub-root nodes (level 1).
  CGFloat currentRadius = [self vertexRadius:1];
  CGFloat theta = 0;
  CGFloat deltaTheta = 2 * M_PI / kRootNodeRank;
  for (NSUInteger i = 0; i < kRootNodeRank; ++i) {
    _vertices.push_back(LTVector2PolarMake(CGPointZero, currentRadius, theta));
    theta += deltaTheta;
    
    // Create triangles of the first level. Because we're cyclic, the last vertex connects to the
    // first one.
    _indices.push_back(0);
    _indices.push_back((uint)_vertices.size() - 1);
    _indices.push_back((i == kRootNodeRank - 1) ? 1 : (uint)_vertices.size());
  }
  
  NSUInteger numberOfParents = kRootNodeRank;
  for (NSUInteger i = 2; i < kNumberOfVertexLevels; ++i) {
    // Last level radius will always be on the boundary (=1).
    CGFloat radius = (i != kNumberOfVertexLevels - 1) ? [self vertexRadius:i] : 1;
    [self createLevelOfVertices:radius numberOfParents:numberOfParents];
    numberOfParents *= 2;
  }
}

- (CGFloat)angleFromPolar:(LTVector2)v centeredAt:(CGPoint)center {
  return std::atan2(v.y - center.y, v.x - center.x);
}

- (CGFloat)vertexRadius:(NSUInteger)level {
  return 1 - std::pow((CGFloat)(kNumberOfVertexLevels - 1 - level) /
                      (kNumberOfVertexLevels - 1), 2);
}

- (void)createLevelOfVertices:(CGFloat)radius numberOfParents:(NSUInteger)numberOfParents {
  // A nice way to count the number of children per parent is to notice that each parent has a left
  // child and a center child (ignoring its right child). Therefore, #children = 2 * #parents.
  NSUInteger numberOfChildren = 2 * numberOfParents;
  NSUInteger originalNumberOfVertices = _vertices.size();
  _vertices.resize(_vertices.size() + numberOfChildren);
  
  // Initial offset should place child between two parents.
  CGFloat theta = [self angleFromPolar:_vertices[originalNumberOfVertices - numberOfParents]
                            centeredAt:CGPointZero] - ((2 * M_PI) / (2 * numberOfParents));
  CGFloat deltaTheta = (2 * M_PI) / numberOfChildren;
  
  // Create all children.
  for (NSUInteger i = 0; i < numberOfChildren; ++i) {
    _vertices[originalNumberOfVertices + i] = LTVector2PolarMake(CGPointZero, radius, theta);
    theta += deltaTheta;
  }
  
  // Create three triangles for each parent vertex.
  for (NSUInteger index = (originalNumberOfVertices - numberOfParents), i = 0;
       index < originalNumberOfVertices; ++index, ++i) {
    // First triangle: parent and two children.
    _indices.push_back((uint)index);
    _indices.push_back((uint)(originalNumberOfVertices + i * 2));
    _indices.push_back((uint)(originalNumberOfVertices + i * 2 + 1));
    
    // Second triangle: parent and two children.
    _indices.push_back((uint)(index));
    _indices.push_back((uint)(originalNumberOfVertices + i * 2 + 1));
    if (index != originalNumberOfVertices - 1) {
      _indices.push_back((uint)(originalNumberOfVertices + i * 2 + 2));
    } else {
      // Cyclic.
      _indices.push_back((uint)(originalNumberOfVertices));
    }
    
    // Third triangle: two parents and one children.
    _indices.push_back((uint)(index));
    if (index != originalNumberOfVertices - 1) {
      _indices.push_back((uint)(originalNumberOfVertices + i * 2 + 2));
      _indices.push_back((uint)(index + 1));
    } else {
      // Cyclic.
      _indices.push_back((uint)(originalNumberOfVertices));
      _indices.push_back((uint)(originalNumberOfVertices - numberOfParents));
    }
  }
}

@synthesize boundaryVertices = _boundaryVertices;

- (LTVector2s)boundaryVertices {
  if (_boundaryVertices.empty()) {
    NSUInteger numBoundaryVertices = kRootNodeRank * std::pow(2, kNumberOfVertexLevels - 2);
    _boundaryVertices.resize(numBoundaryVertices);
    for (NSUInteger i = 0; i < numBoundaryVertices; ++i) {
      _boundaryVertices[i] = _vertices[_vertices.size() - numBoundaryVertices + i];
    }
  }
  return _boundaryVertices;
}

#pragma mark -
#pragma mark Utility
#pragma mark -

- (NSUInteger)numberOfVertices {
  return _vertices.size();
}

- (NSUInteger)numberOfBoundaryVertices {
  return _boundaryVertices.size();
}

- (NSUInteger)numberOfVertexLevels {
  return kNumberOfVertexLevels;
}

- (NSUInteger)rootNodeRank {
  return kRootNodeRank;
}

- (NSUInteger)firstVertexIndex:(NSUInteger)level {
  LTParameterAssert(level < kNumberOfVertexLevels);
  return (level == 0) ? 0 : std::pow(2, 2 + level) - (kRootNodeRank - 1);
}

- (NSUInteger)numOfVerticesInLevel:(NSUInteger)level {
  LTParameterAssert(level < kNumberOfVertexLevels);
  return (level == 0) ? 1 : kRootNodeRank * std::pow(2, level - 1);
}

- (NSUInteger)firstBoundaryVertexIndex {
  return [self firstVertexIndex:self.numberOfVertexLevels - 1];
}

@end
