// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBipartiteGraph.h"

@interface LTBipartiteGraphTestObject : NSObject <NSCopying>
@property (nonatomic) NSUInteger value;
@end

@implementation LTBipartiteGraphTestObject

- (id)copyWithZone:(nullable NSZone *)zone {
  LTBipartiteGraphTestObject *result = [[LTBipartiteGraphTestObject allocWithZone:zone] init];
  result.value = self.value;
  return result;
}

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  }

  if (![object isMemberOfClass:[self class]]) {
    return NO;
  }

  return ((LTBipartiteGraphTestObject *)object).value == self.value;
}

- (NSUInteger)hash {
  return self.value;
}

@end

SpecBegin(LTBipartiteGraph)

__block LTBipartiteGraph *graph;
__block LTBipartiteGraphTestObject *vertexInA;
__block LTBipartiteGraphTestObject *vertexInB;
__block LTBipartiteGraphTestObject *anotherVertexInB;

beforeEach(^{
  graph = [[LTBipartiteGraph alloc] init];
  vertexInA = [[LTBipartiteGraphTestObject alloc] init];
  vertexInA.value = 7;
  vertexInB = [[LTBipartiteGraphTestObject alloc] init];
  vertexInB.value = 8;
  anotherVertexInB = [[LTBipartiteGraphTestObject alloc] init];
  anotherVertexInB.value = 9;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(graph).toNot.beNil();
    expect(graph.verticesInPartitionA).to.beEmpty();
    expect(graph.verticesInPartitionB).to.beEmpty();
  });
});

context(@"adding vertices", ^{
  it(@"should correctly add a vertex", ^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    expect(graph.verticesInPartitionA).to.equal([NSSet setWithObject:vertexInA]);
    expect(graph.verticesInPartitionB).to.beEmpty();

    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    expect(graph.verticesInPartitionA).to.equal([NSSet setWithObject:vertexInA]);
    expect(graph.verticesInPartitionB).to.equal([NSSet setWithObject:vertexInB]);

    [graph addVertex:anotherVertexInB toPartition:LTBipartiteGraphPartitionB];
    expect(graph.verticesInPartitionA).to.equal([NSSet setWithObject:vertexInA]);
    expect(graph.verticesInPartitionB)
        .to.equal([NSSet setWithArray:@[vertexInB, anotherVertexInB]]);
  });

  context(@"adding same vertex multiple times", ^{
    beforeEach(^{
      [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    });

    it(@"should silently ignore when attempting to add a vertex twice to the same partition", ^{
      expect(^{
        [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should not affect edges when attempting to add a vertex twice to the same partition", ^{
      [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
      [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];

      [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];

      expect([graph verticesAdjacentToVertex:vertexInA]).to.equal([NSSet setWithObject:vertexInB]);
      expect([graph verticesAdjacentToVertex:vertexInB]).to.equal([NSSet setWithObject:vertexInA]);
    });

    it(@"should raise when attempting to add a vertex to different partitions", ^{
      expect(^{
        [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionB];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  it(@"should not automatically add edges to an added vertex", ^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    expect([graph verticesAdjacentToVertex:vertexInA]).to.beEmpty();
    expect([graph verticesAdjacentToVertex:vertexInB]).to.beEmpty();
  });
});

context(@"replacing vertices", ^{
  __block LTBipartiteGraphTestObject *newVertexInA;

  beforeEach(^{
    newVertexInA = [[LTBipartiteGraphTestObject alloc] init];
    newVertexInA.value = 6;
  });

  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addVertex:anotherVertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addEdgesBetweenVertex:vertexInA
                     andVertices:[NSSet setWithArray:@[vertexInB, anotherVertexInB]]];
  });

  it(@"should correctly replace a vertex", ^{
    [graph replaceVertex:vertexInA byVertex:newVertexInA];

    expect(graph.verticesInPartitionA).to.equal([NSSet setWithObject:newVertexInA]);
    expect(graph.verticesInPartitionB)
        .to.equal([NSSet setWithArray:@[vertexInB, anotherVertexInB]]);
  });

  it(@"should raise when attempting to replace a non-existent vertex", ^{
    expect(^{
      [graph replaceVertex:[[LTBipartiteGraphTestObject alloc] init] byVertex:newVertexInA];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should update the edges of the graph correctly", ^{
    [graph replaceVertex:vertexInA byVertex:newVertexInA];

    NSSet *vertices = [graph verticesAdjacentToVertex:newVertexInA];
    expect(vertices).to.equal([NSSet setWithArray:@[vertexInB, anotherVertexInB]]);
    vertices = [graph verticesAdjacentToVertex:vertexInB];
    expect(vertices).to.equal([NSSet setWithObject:newVertexInA]);
    vertices = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(vertices).to.equal([NSSet setWithObject:newVertexInA]);
  });
});

context(@"removing vertices", ^{
  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
  });

  it(@"should correctly remove a vertex", ^{
    expect(graph.verticesInPartitionA).to.equal([NSSet setWithObject:vertexInA]);
    expect(graph.verticesInPartitionB).to.equal([NSSet setWithObject:vertexInB]);

    [graph removeVertex:vertexInA];
    expect(graph.verticesInPartitionA).to.beEmpty();
    expect(graph.verticesInPartitionB).to.equal([NSSet setWithObject:vertexInB]);

    [graph removeVertex:vertexInB];
    expect(graph.verticesInPartitionA).to.beEmpty();
    expect(graph.verticesInPartitionB).to.beEmpty();
  });

  it(@"should raise when attempting to remove a non-existent vertex", ^{
    expect(^{
      [graph removeVertex:[[LTBipartiteGraphTestObject alloc] init]];
    }).toNot.raise(NSInvalidArgumentException);
  });
});

context(@"providing information about vertices", ^{
  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
  });

  it(@"should return the correct partition of existing vertices", ^{
    expect([graph partitionOfVertex:vertexInA]).to.equal(LTBipartiteGraphPartitionA);
    expect([graph partitionOfVertex:vertexInB]).to.equal(LTBipartiteGraphPartitionB);
  });

  it(@"should return the correct result for non-existing vertices", ^{
    expect([graph partitionOfVertex:anotherVertexInB]).to.equal(LTBipartiteGraphPartitionNone);
  });
});

context(@"adding edges", ^{
  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addVertex:anotherVertexInB toPartition:LTBipartiteGraphPartitionB];
  });

  it(@"should correctly add single edges", ^{
    [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];
    NSSet *vertices = [graph verticesAdjacentToVertex:vertexInA];
    expect(vertices).to.equal([NSSet setWithObject:vertexInB]);
    vertices = [graph verticesAdjacentToVertex:vertexInB];
    expect(vertices).to.equal([NSSet setWithObject:vertexInA]);

    [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:anotherVertexInB]];
    vertices = [graph verticesAdjacentToVertex:vertexInA];
    expect(vertices).to.equal([NSSet setWithArray:@[vertexInB, anotherVertexInB]]);
    vertices = [graph verticesAdjacentToVertex:vertexInB];
    expect(vertices).to.equal([NSSet setWithObject:vertexInA]);
    vertices = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(vertices).to.equal([NSSet setWithObject:vertexInA]);
  });

  it(@"should correctly add multiple edges", ^{
    [graph addEdgesBetweenVertex:vertexInA
                     andVertices:[NSSet setWithArray:@[vertexInB, anotherVertexInB]]];
    NSSet *vertices = [graph verticesAdjacentToVertex:vertexInA];
    expect(vertices).to.equal([NSSet setWithArray:@[vertexInB, anotherVertexInB]]);
    vertices = [graph verticesAdjacentToVertex:vertexInB];
    expect(vertices).to.equal([NSSet setWithObject:vertexInA]);
    vertices = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(vertices).to.equal([NSSet setWithObject:vertexInA]);
  });

  it(@"should raise when attempting to add an edge between two already connected vertices", ^{
    [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];
    expect(^{
      [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to add an edge between non-existent vertices", ^{
    expect(^{
      [graph addEdgesBetweenVertex:vertexInA
                       andVertices:[NSSet setWithObject:[[LTBipartiteGraphTestObject alloc] init]]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [graph addEdgesBetweenVertex:[[LTBipartiteGraphTestObject alloc] init]
                       andVertices:[NSSet setWithObject:vertexInA]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to add an edge between two vertices of the same partition", ^{
    expect(^{
      [graph addEdgesBetweenVertex:vertexInB
                       andVertices:[NSSet setWithObject:anotherVertexInB]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"removing edges", ^{
  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addVertex:anotherVertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addEdgesBetweenVertex:vertexInA
                     andVertices:[NSSet setWithArray:@[vertexInB, anotherVertexInB]]];
  });

  it(@"should correctly remove single edges", ^{
    [graph removeEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];

    NSSet *objects = [graph verticesAdjacentToVertex:vertexInA];
    expect(objects).to.equal([NSSet setWithObject:anotherVertexInB]);
    objects = [graph verticesAdjacentToVertex:vertexInB];
    expect(objects).to.beEmpty();
    objects = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(objects).to.equal([NSSet setWithObject:vertexInA]);

    [graph removeEdgesBetweenVertex:anotherVertexInB andVertices:[NSSet setWithObject:vertexInA]];

    objects = [graph verticesAdjacentToVertex:vertexInA];
    expect(objects).to.beEmpty();
    objects = [graph verticesAdjacentToVertex:vertexInB];
    expect(objects).to.beEmpty();
    objects = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(objects).to.beEmpty();
  });

  it(@"should correctly remove multiple edges", ^{
    [graph removeEdgesBetweenVertex:vertexInA
                        andVertices:[NSSet setWithArray:@[vertexInB, anotherVertexInB]]];

    NSSet *objects = [graph verticesAdjacentToVertex:vertexInA];
    expect(objects).to.beEmpty();
    objects = [graph verticesAdjacentToVertex:vertexInB];
    expect(objects).to.beEmpty();
    objects = [graph verticesAdjacentToVertex:anotherVertexInB];
    expect(objects).to.beEmpty();
  });
});

context(@"providing information about edges", ^{
  beforeEach(^{
    [graph addVertex:vertexInA toPartition:LTBipartiteGraphPartitionA];
    [graph addVertex:vertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addVertex:anotherVertexInB toPartition:LTBipartiteGraphPartitionB];
    [graph addEdgesBetweenVertex:vertexInA andVertices:[NSSet setWithObject:vertexInB]];
  });

  it(@"should return the correct vertices adjacent to connected vertices", ^{
    expect([graph verticesAdjacentToVertex:vertexInA]).to.equal([NSSet setWithObject:vertexInB]);
    expect([graph verticesAdjacentToVertex:vertexInB]).to.equal([NSSet setWithObject:vertexInA]);
  });

  it(@"should return an empty set for queries of vertices adjacent to unconnected vertices", ^{
    expect([graph verticesAdjacentToVertex:anotherVertexInB]).to.beEmpty();
  });

  it(@"should return nil for queries of vertices adjacent to non-existing vertices", ^{
    expect([graph verticesAdjacentToVertex:[[LTBipartiteGraphTestObject alloc] init]]).to.beNil();
  });
});

SpecEnd
