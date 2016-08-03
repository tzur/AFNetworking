// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

@class LTAttributeData, LTGPUStruct, LTIndicesData;

/// Value class with necessary data for rendering a regular grid of vertices.
@interface LTRegularGridMesh : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the desirable grid mesh \c size. \c size must be positive in both dimensions.
- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;

/// Struct for describing a given vertex in the grid mesh. Contains a single \c LTVector2 field
/// named \c gridPosition with the 2D position of a given point on the grid.
+ (LTGPUStruct *)vertexStruct;

/// Object which contains the vertices which compose the given grid. Data is ordered as a
/// <tt>size.height x size.widht</tt> matrix of \c vertexStruct values in row major order. For a
/// given vertex, the \c gridPosition is set to be the 2D normalized <tt>[0, 1]x[0, 1]</tt> position
/// of the vertex point on the grid with respect to the grid rectangle i.e, the vertex which
/// describes the <tt>(x, y)</tt> point on the grid will have \c gridPosition value of
/// <tt>(x / (size.width), y / (size.height)</tt> where \c x and \c y are zero based indices in
/// <tt>[0, size.width]</tt> and <tt>[0, size.height]</tt> respectivelty.
@property (readonly, nonatomic) LTAttributeData *verticesData;

/// Object which contains the indices for creating a triangular mesh from the grid vertcies. For
/// each grid quad, indices data contains \c 6 values for describing the quad with two triangles.
/// Therefore, the indcies count is equal to <tt>6 * (size.width) * (size.height)</tt> (\c 6 times
/// the number of grid quads). The grid quads described by the indices are ordered as a
/// <tt>(size.height) x (size.width)</tt> matrix with row major order. For a quad with vertices
/// <tt>(0, 1, 2, 3)</tt> where \c 0 is the top left vertex and vertices are in clockwise order, the
/// two quad triangles are built from indices <tt>(0, 1, 2)</tt> and <tt>(3, 2, 0)</tt>.
@property (readonly, nonatomic) LTIndicesData *triangularIndices;

/// Object which contains the indices for creating a wireframe from the grid vertcies. For each grid
/// quad, indices data contains \c 8 values for describing the quad \c 4 sides. Therefore, the
/// number of indices is <tt>8 * (size.width) * (size.height)</tt> (\c 8 times the number of grid
/// quads). The grid quads described by the indices are ordered as a
/// <tt>(size.height) x (size.width)</tt> matrix with row major order. For a quad with vertices
/// <tt>(0, 1, 2, 3)</tt> where 0 is the top left vertex and vertices are clockwised ordered, the
/// quad \c 4 sides are built from indices <tt>(0, 1)</tt>, <tt>(1, 2)</tt>, <tt>(2, 3)</tt> and
/// <tt>(3, 0)</tt>.
@property (readonly, nonatomic) LTIndicesData *wireframeIndices;

@end

NS_ASSUME_NONNULL_END
