// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTRegularGridMesh.h"

#import "LTAttributeData.h"
#import "LTGPUStruct.h"
#import "LTIndicesData.h"

SpecBegin(LTRegularGridMesh)

context(@"intiailization", ^{
  it(@"should initialize with valid size", ^{
    expect(^{
      LTRegularGridMesh __unused *mesh =
          [[LTRegularGridMesh alloc] initWithSize:CGSizeMakeUniform(1)];
    }).notTo.raiseAny();
  });

  it(@"should raise with invalid size", ^{
    expect(^{
      LTRegularGridMesh __unused *mesh =
          [[LTRegularGridMesh alloc] initWithSize:CGSizeMake(0, 1)];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTRegularGridMesh __unused *mesh =
          [[LTRegularGridMesh alloc] initWithSize:CGSizeMake(1, 0)];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  __block LTRegularGridMesh *mesh;

  beforeEach(^{
    mesh = [[LTRegularGridMesh alloc] initWithSize:CGSizeMake(4, 5)];
  });

  afterEach(^{
    mesh = nil;
  });

  it(@"should have correct vertices data", ^{
    LTGPUStruct *vertexStruct = [[mesh class] vertexStruct];
    expect(mesh.verticesData.gpuStruct).to.equal(vertexStruct);

    LTVector2s vertices(30);
    for (int y = 0; y < 6; ++y) {
      for (int x = 0; x < 5; ++x) {
        vertices[y * 5 + x] = LTVector2(0.25 * x, 0.2 * y);
      }
    }

    NSData *expectedData = [NSData dataWithBytes:vertices.data()
                                          length:vertices.size() * vertexStruct.size];
    expect(mesh.verticesData.data).to.equal(expectedData);
  });

  it(@"should have correct triangular indices", ^{
    std::vector<GLuint> expectedIndices(6 * 20);
    for (int y = 0; y < 5; ++y) {
      for (int x = 0; x < 4; ++x) {
        GLuint topLeft = y * 5 + x;
        GLuint topRight = y * 5 + x + 1;
        GLuint bottomLeft = (y + 1) * 5 + x;
        GLuint bottomRight = (y + 1) * 5 + x + 1;
        expectedIndices[6 * (4 * y + x)] = topLeft;
        expectedIndices[6 * (4 * y + x) + 1] = topRight;
        expectedIndices[6 * (4 * y + x) + 2] = bottomRight;
        expectedIndices[6 * (4 * y + x) + 3] = bottomRight;
        expectedIndices[6 * (4 * y + x) + 4] = bottomLeft;
        expectedIndices[6 * (4 * y + x) + 5] = topLeft;
      }
    }

    expect(mesh.triangularIndices).to.equal([LTIndicesData dataWithIntegerIndices:expectedIndices]);
  });

  it(@"should have correct wireframe indices", ^{
    std::vector<GLuint> expectedIndices(8 * 20);
    for (int y = 0; y < 5; ++y) {
      for (int x = 0; x < 4; ++x) {
        GLuint topLeft = y * 5 + x;
        GLuint topRight = y * 5 + x + 1;
        GLuint bottomLeft = (y + 1) * 5 + x;
        GLuint bottomRight = (y + 1) * 5 + x + 1;
        expectedIndices[8 * (4 * y + x)] = topLeft;
        expectedIndices[8 * (4 * y + x) + 1] = topRight;
        expectedIndices[8 * (4 * y + x) + 2] = topRight;
        expectedIndices[8 * (4 * y + x) + 3] = bottomRight;
        expectedIndices[8 * (4 * y + x) + 4] = bottomRight;
        expectedIndices[8 * (4 * y + x) + 5] = bottomLeft;
        expectedIndices[8 * (4 * y + x) + 6] = bottomLeft;
        expectedIndices[8 * (4 * y + x) + 7] = topLeft;
      }
    }

    expect(mesh.wireframeIndices).to.equal([LTIndicesData dataWithIntegerIndices:expectedIndices]);
  });
});

SpecEnd
