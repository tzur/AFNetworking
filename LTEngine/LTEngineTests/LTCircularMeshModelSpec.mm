// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularMeshModel.h"

SpecBegin(LTCircularMeshModel)

__block LTCircularMeshModel *meshModel;

it(@"should initialize without raising exception", ^{
  expect(^{
    meshModel = [[LTCircularMeshModel alloc] init];
  }).notTo.raiseAny();
});

context(@"accessors", ^{
  beforeEach(^{
    meshModel = [[LTCircularMeshModel alloc] init];
  });

  it(@"should return correct number of vertices and indices", ^{
    NSUInteger numberOfVertices = meshModel.numberOfVertexLevels + 2 * meshModel.rootNodeRank *
        (std::pow(2, meshModel.numberOfVertexLevels - 2) - 1);
    expect(meshModel.vertices.size()).to.equal(numberOfVertices);
    expect(meshModel.indices.size()).to.equal(9168);
  });

  it(@"should return correct vertex numbers per level", ^{
    expect([meshModel numOfVerticesInLevel:0]).to.equal(1);
    expect([meshModel numOfVerticesInLevel:1]).to.equal(meshModel.rootNodeRank);
    expect([meshModel numOfVerticesInLevel:5]).to.equal(meshModel.rootNodeRank * std::pow(2, 4));
  });

  it(@"should return correct vertex first index per level", ^{
    expect([meshModel firstVertexIndex:0]).to.equal(0);
    expect([meshModel firstVertexIndex:1]).to.equal(1);
    expect([meshModel firstVertexIndex:5]).to.equal(std::pow(2, 7) - (meshModel.rootNodeRank - 1));
    NSUInteger firstBoundaryVertexIndex =
        std::pow(2, meshModel.numberOfVertexLevels + 1) - (meshModel.rootNodeRank - 1);
    expect(meshModel.firstBoundaryVertexIndex).to.equal(firstBoundaryVertexIndex);
  });

  it(@"should return correct boundary vertices", ^{
    expect(meshModel.boundaryVertices.size()).to
        .equal([meshModel numOfVerticesInLevel:meshModel.numberOfVertexLevels - 1]);
    for (LTVector2s::size_type index = 0; index < meshModel.boundaryVertices.size(); ++index) {
      expect(meshModel.boundaryVertices[index])
          .to.equal(meshModel.vertices[meshModel.firstBoundaryVertexIndex + index]);
    }
  });
});

SpecEnd
