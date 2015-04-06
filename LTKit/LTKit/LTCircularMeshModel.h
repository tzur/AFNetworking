// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

/// Holds a normalized model for a circular mesh with vetrices ranging between [-1, 1]. The mesh is
/// sparse in the middle of the circle, and becomes dense as we move further away from it.
@interface LTCircularMeshModel : NSObject

/// Returns the first vertex index for a given \c level.
- (NSUInteger)firstVertexIndex:(NSUInteger)level;

/// Returns the number of vertices in a given \c level.
- (NSUInteger)numOfVerticesInLevel:(NSUInteger)level;

/// Returns the first boundary vertex index.
- (NSUInteger)firstBoundaryVertexIndex;

/// Array describing circular mesh vertices coordinates.
///
/// @note accessing this property is a heavy operation since it copies the entire vector.
@property (readonly, nonatomic) LTVector2s vertices;

/// Array of vertices found on the boundary of the mesh.
///
/// @note accessing this property is a heavy operation since it copies the entire vector.
@property (readonly, nonatomic) LTVector2s boundaryVertices;

/// \c uint array describing circular mesh indices.
///
/// @note accessing this property is a heavy operation since it copies the entire vector.
@property (readonly, nonatomic) GLuints indices;

/// Number of vertices in the circular mesh.
@property (readonly, nonatomic) NSUInteger numberOfVertices;

/// Number of boundary vertices in the circular mesh.
@property (readonly, nonatomic) NSUInteger numberOfBoundaryVertices;

/// The rank of the central vertex of the circular mesh.
@property (readonly, nonatomic) NSUInteger rootNodeRank;

/// Number of vertex levels in the circular mesh.
@property (readonly, nonatomic) NSUInteger numberOfVertexLevels;

@end
