// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Partitions of a bipartite graph.
typedef NS_ENUM(NSInteger, LTBipartiteGraphPartition) {
  /// Indicates no partition of a bipartite graph.
  LTBipartiteGraphPartitionNone = -1,
  /// First partition.
  LTBipartiteGraphPartitionA,
  /// Second partition.
  LTBipartiteGraphPartitionB
};

/// Object representing a mutable, unweighted, undirected bipartite graph
/// (@see https://en.wikipedia.org/wiki/Bipartite_graph). The object allows adding, replacement and
/// removal of vertices into the two partitions. In addition, undirected, unweighted edges between
/// vertices of opposite partitions can be added and removed. Vertices of this graph must conform to
/// the \c NSCopying protocol and implement both the \c isEqual: method and the \c hash method
/// according to their needs. The time complexity statements are under the assumption that value
/// insertion and retrieval of \c NSDictionary is in \c O(1).
@interface LTBipartiteGraph : NSObject

/// Adds a \c copy of the given \c vertex to the given \c partition. Is silently ignored, if the
/// given \c vertex already exists in the graph. After adding, the graph does not contain any edges
/// involving \c vertex.
///
/// Time complexity: \c O(1)
- (void)addVertex:(id<NSCopying>)vertex toPartition:(LTBipartiteGraphPartition)partition;

/// Replaces the given \c vertexToReplace by the given \c newVertex. The given \c vertexToReplace
/// must exist in this graph, while the given \c newVertex must not exist in this graph. All
/// possibly existing edges involving the \c vertexToReplace are updated in order to reflect the
/// replacement.
///
/// Time complexity: \c O(n), where \c n is the number of edges involving \c vertexToReplace.
- (void)replaceVertex:(id<NSCopying>)vertexToReplace byVertex:(id<NSCopying>)newVertex;

/// Removes the given \c vertex from this graph. Is silently ignored, if the given \c vertex does
/// not exist in the graph.
///
/// Time complexity: \c O(n), where \c n is the number of edges involving \c vertex.
- (void)removeVertex:(id<NSCopying>)vertex;

/// Returns the partition to which the given \c vertex belongs or \c LTBipartiteGraphPartitionNone
/// if the \c vertex does not belong to any partition.
///
/// Time complexity: \c O(1)
- (LTBipartiteGraphPartition)partitionOfVertex:(id<NSCopying>)vertex;

/// Adds edges between the given \c vertex and the given \c vertices. The \c vertex and the
/// \c vertices must exist in this graph and belong to opposite partitions. The intersection between
/// the given \c vertices and \c verticesAdjacentToVertex:vertex must be empty.
///
/// Time complexity: \c O(|vertices|)
- (void)addEdgesBetweenVertex:(id<NSCopying>)vertex andVertices:(NSSet<id<NSCopying>> *)vertices;

/// Removes any existing edges between the given \c vertex and the given \c vertices. The \c vertex
/// and the \c vertices must exist in this graph and belong to opposite partitions. The given
/// \c vertices must be a subset of the set returned by \c verticesAdjacentToVertex:vertex.
///
/// Time complexity: \c O(|vertices|)
- (void)removeEdgesBetweenVertex:(id<NSCopying>)vertex andVertices:(NSSet<id<NSCopying>> *)vertices;

/// Returns the vertices adjacent to the given \c vertex. Returns \c nil if the given \c vertex does
/// not exist in this graph.
///
/// Time complexity: \c O(n), where \c n is the number of vertices sharing an edge with \c vertex.
- (nullable NSSet<id<NSCopying>> *)verticesAdjacentToVertex:(id<NSCopying>)vertex;

/// Vertices in partition \c A of this graph.
///
/// Time complexity: \c O(n), where \c n is the number of vertices in partition A.
@property (readonly, nonatomic) NSSet<id<NSCopying>> *verticesInPartitionA;

/// Vertices in partition \c B of this graph.
///
/// Time complexity: \c O(n), where \c n is the number of vertices in partition B.
@property (readonly, nonatomic) NSSet<id<NSCopying>> *verticesInPartitionB;

@end

NS_ASSUME_NONNULL_END
