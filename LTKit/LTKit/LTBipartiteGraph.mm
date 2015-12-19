// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBipartiteGraph.h"

NS_ASSUME_NONNULL_BEGIN

/// Type definition for vertices of this graph.
typedef id<NSCopying> LTVertex;

/// Type definition for dictionaries representing the edges of a bipartite graph. Any such
/// dictionary maps vertices of a partition to a set of vertices in the opposite partition.
typedef NSMutableDictionary<LTVertex, NSMutableSet<LTVertex> *> LTBipartiteGraphEdgeMap;

@interface LTBipartiteGraph ()

/// Tuple of dictionaries, one for each partition of this graph, representing the edges of this
/// graph. Each dictionary maps the vertices of a partition to a set of vertices in the opposite
/// partition.
@property (strong, nonatomic) NSArray<LTBipartiteGraphEdgeMap *> *edgeMaps;

@end

@implementation LTBipartiteGraph

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    self.edgeMaps = @[[NSMutableDictionary dictionary], [NSMutableDictionary dictionary]];
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  LTBipartiteGraph *graph = (LTBipartiteGraph *)object;

  return [self.verticesInPartitionA isEqualToSet:graph.verticesInPartitionA] &&
      [self.verticesInPartitionB isEqualToSet:graph.verticesInPartitionB];
}

- (NSUInteger)hash {
  return self.edgeMaps.hash;
}

#pragma mark -
#pragma mark Adding Vertices
#pragma mark -

- (void)addVertex:(LTVertex)vertex toPartition:(LTBipartiteGraphPartition)partition {
  LTParameterAssert(partition >= 0 && partition < (NSInteger)self.edgeMaps.count,
                    @"Invalid partition (%ld) provided", (long)partition);

  LTBipartiteGraphPartition partitionOfVertex = [self partitionOfVertex:vertex];
  if (partitionOfVertex != LTBipartiteGraphPartitionNone) {
    LTParameterAssert(partition == partitionOfVertex,
                      @"Attempting to add vertex (%@) existing in partition (%ld) to partition "
                      "(%ld)", vertex, (long)partitionOfVertex, (long)partition);
    return;
  }
  self.edgeMaps[partition][vertex] = [NSMutableSet set];
}

#pragma mark -
#pragma mark Replacing Vertices
#pragma mark -

- (void)replaceVertex:(LTVertex)vertexToReplace byVertex:(LTVertex)newVertex {
  LTBipartiteGraphPartition partitionOfVertexToReplace = [self partitionOfVertex:vertexToReplace];
  LTParameterAssert(partitionOfVertexToReplace != LTBipartiteGraphPartitionNone,
                    @"Attempting to replace non-existing vertex (%@)", vertexToReplace);

  LTBipartiteGraphPartition partitionOfNewVertex = [self partitionOfVertex:newVertex];
  LTParameterAssert(partitionOfNewVertex == LTBipartiteGraphPartitionNone,
                    @"Attempting to replace vertex (%@) in partition (%ld) by vertex (%@) already "
                    "existing in partition (%ld)", vertexToReplace,
                    (long)partitionOfVertexToReplace, newVertex, (long)partitionOfNewVertex);

  NSSet *adjacentVertices = [self.edgeMaps[partitionOfVertexToReplace][vertexToReplace] copy];
  [self removeVertex:vertexToReplace];
  [self addVertex:newVertex toPartition:partitionOfVertexToReplace];
  [self addEdgesBetweenVertex:newVertex andVertices:adjacentVertices];
}

#pragma mark -
#pragma mark Removing Vertices
#pragma mark -

- (void)removeVertex:(LTVertex)vertex {
  LTBipartiteGraphPartition partition = [self partitionOfVertex:vertex];
  if (partition == LTBipartiteGraphPartitionNone) {
    return;
  }

  NSSet<LTVertex> *adjacentVertices = [self verticesAdjacentToVertex:vertex];
  [self removeEdgesBetweenVertex:vertex andVertices:adjacentVertices];
  [self.edgeMaps[[self partitionOfVertex:vertex]] removeObjectForKey:vertex];
}

#pragma mark -
#pragma mark Vertex Information
#pragma mark -

- (LTBipartiteGraphPartition)partitionOfVertex:(LTVertex)vertex {
  if (self.edgeMaps[LTBipartiteGraphPartitionA][vertex]) {
    return LTBipartiteGraphPartitionA;
  } else if (self.edgeMaps[LTBipartiteGraphPartitionB][vertex]) {
    return LTBipartiteGraphPartitionB;
  }
  return LTBipartiteGraphPartitionNone;
}

#pragma mark -
#pragma mark Adding Edges
#pragma mark -

- (void)addEdgesBetweenVertex:(LTVertex)vertex andVertices:(NSSet<LTVertex> *)vertices {
  LTBipartiteGraphPartition partition = [self partitionOfVertex:vertex];
  LTBipartiteGraphPartition oppositePartition = [self oppositePartition:partition];
  [self validateVertices:vertices inPartition:oppositePartition];

  [self addEdgesFromVertex:vertex inPartition:partition toVertices:vertices];
  [self addEdgesFromVertices:vertices inPartition:oppositePartition toVertex:vertex];
}

 - (LTBipartiteGraphPartition)oppositePartition:(LTBipartiteGraphPartition)partition {
   LTParameterAssert(partition != LTBipartiteGraphPartitionNone,
                     @"Attempting to compute opposite partition of LTBipartiteGraphPartitionNone");
   return partition == LTBipartiteGraphPartitionA ?
       LTBipartiteGraphPartitionB : LTBipartiteGraphPartitionA;
 }

- (void)validateVertices:(NSSet<LTVertex> *)vertices
             inPartition:(LTBipartiteGraphPartition)partition {
  NSSet *verticesInPartition = [NSSet setWithArray:[self.edgeMaps[partition] allKeys]];

  if (![vertices isSubsetOfSet:verticesInPartition]) {
    NSMutableSet<LTVertex> *minusSet = [vertices mutableCopy];
    [minusSet minusSet:verticesInPartition];
    LTParameterAssert(NO, @"Certain vertices (%@) of given vertices (%@) are not among vertices "
                      "(%@) of partition (%ld)", minusSet, vertices, verticesInPartition,
                     (long)partition);
  }
}

- (void)addEdgesFromVertex:(LTVertex)vertex inPartition:(LTBipartiteGraphPartition)partition
                toVertices:(NSSet<LTVertex> *)vertices {
  NSMutableSet<LTVertex> *adjacentVertices = self.edgeMaps[partition][vertex];
  NSMutableSet<LTVertex> *intersectionSet = [adjacentVertices mutableCopy];
  [intersectionSet intersectSet:vertices];

  LTParameterAssert(!intersectionSet.count,
                    @"Attempting to add already existing edge from (%@) to vertex (%@)", vertex,
                    [intersectionSet anyObject]);

  [adjacentVertices addObjectsFromArray:[vertices allObjects]];
}

- (void)addEdgesFromVertices:(NSSet<LTVertex> *)vertices
                 inPartition:(LTBipartiteGraphPartition)partition toVertex:(LTVertex)vertex {
  for (LTVertex affectedVertex in vertices) {
    NSMutableSet<LTVertex> *adjacentVertices = self.edgeMaps[partition][affectedVertex];
    LTAssert(![adjacentVertices containsObject:vertex],
             @"Attempting to add already existing edge from vertex (%@) to vertex (%@)",
             affectedVertex, vertex);
    [adjacentVertices addObject:vertex];
  }
}

#pragma mark -
#pragma mark Removing Edges
#pragma mark -

- (void)removeEdgesBetweenVertex:(LTVertex)vertex andVertices:(NSSet<LTVertex> *)vertices {
  LTBipartiteGraphPartition partition = [self partitionOfVertex:vertex];
  LTBipartiteGraphPartition oppositePartition = [self oppositePartition:partition];
  [self validateVertices:vertices inPartition:oppositePartition];

  [self removeEdgesFromVertices:vertices inPartition:oppositePartition toVertex:vertex];
  [self removeEdgesFromVertex:vertex inPartition:partition toVertices:vertices];
}

- (void)removeEdgesFromVertices:(NSSet<LTVertex> *)vertices
                    inPartition:(LTBipartiteGraphPartition)partition toVertex:(LTVertex)vertex {
  for (LTVertex affectedVertex in vertices) {
    NSMutableSet<LTVertex> *adjacentVertices = self.edgeMaps[partition][affectedVertex];
    LTParameterAssert([adjacentVertices containsObject:vertex],
                      @"Attempting to remove non-existent edge from vertex (%@) to vertex (%@)",
                      affectedVertex, vertex);
    [adjacentVertices removeObject:vertex];
  }
}

- (void)removeEdgesFromVertex:(LTVertex)vertex inPartition:(LTBipartiteGraphPartition)partition
                   toVertices:(NSSet<LTVertex> *)vertices {
  NSMutableSet<LTVertex> *adjacentVertices = self.edgeMaps[partition][vertex];

  for (LTVertex vertexToRemove in vertices) {
    LTParameterAssert([adjacentVertices containsObject:vertexToRemove],
                      @"Attempting to remove non-existent edge from vertex (%@) to vertices (%@)",
                      vertex, vertexToRemove);
    [adjacentVertices removeObject:vertexToRemove];
  }
}

#pragma mark -
#pragma mark Edge Information
#pragma mark -

- (nullable NSSet<LTVertex> *)verticesAdjacentToVertex:(LTVertex)vertex {
  LTBipartiteGraphPartition partition = [self partitionOfVertex:vertex];

  if (partition == LTBipartiteGraphPartitionNone) {
    return nil;
  }

  return [self.edgeMaps[partition][vertex] copy];
}

#pragma mark -
#pragma mark Public Properties
#pragma mark -

- (NSSet<LTVertex> *)verticesInPartitionA {
  return [NSSet setWithArray:[self.edgeMaps[LTBipartiteGraphPartitionA] allKeys]];
}

- (NSSet<LTVertex> *)verticesInPartitionB {
  return [NSSet setWithArray:[self.edgeMaps[LTBipartiteGraphPartitionB] allKeys]];
}

@end

NS_ASSUME_NONNULL_END
