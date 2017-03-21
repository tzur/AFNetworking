// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTRegularGridMesh.h"

#import "LTAttributeData.h"
#import "LTGPUStruct.h"
#import "LTIndicesData.h"

NS_ASSUME_NONNULL_BEGIN

/// Struct for describing a given vertex in the grid mesh. Contains a single \c LTVector2 field
/// named \c gridPosition with the 2D position of a given point on the grid.
///
/// @see \c verticesData documentation for more information.
LTGPUStructMake(LTRegularGridMeshVertex,
                LTVector2, gridPosition);

@interface LTRegularGridMesh ()

/// Size of the grid.
@property (readonly, nonatomic) CGSize size;

@end

@implementation LTRegularGridMesh

@synthesize wireframeIndices = _wireframeIndices;

- (instancetype)initWithSize:(CGSize)size {
  LTParameterAssert(size.width > 0 && size.height > 0, @"input size (%@) must be positive in both "
                    "dimensions", NSStringFromCGSize(size));
  if (self = [super init]) {
    _size = size;

    [self createVerticesData];
    [self createTriangularIndices];
  }
  return self;
}

- (void)createVerticesData {
  NSUInteger cols = self.size.width;
  NSUInteger rows = self.size.height;
  std::vector<LTRegularGridMeshVertex> vertexData((rows + 1) * (cols + 1));
  LTVector2 size(cols, rows);
  for (NSUInteger i = 0, idx = 0; i <= rows; ++i) {
    for (NSUInteger j = 0; j <= cols; ++j, ++idx) {
      vertexData[idx] = {.gridPosition = LTVector2(j, i) / size};
    }
  }

  NSData *data = [NSData dataWithBytes:vertexData.data()
                                length:vertexData.size() * [self class].vertexStruct.size];
  _verticesData = [[LTAttributeData alloc] initWithData:data
                                    inFormatOfGPUStruct:[self class].vertexStruct];
}

- (void)createTriangularIndices {
  GLuint cols = self.size.width;
  GLuint rows = self.size.height;
  std::vector<GLuint> indicesData(rows * cols * 6);
  for (GLuint i = 0, idx = 0; i < rows; ++i) {
    for (GLuint j = 0; j < cols; ++j) {
      GLuint topLeft = i * (cols + 1) + j;
      GLuint topRight = i * (cols + 1) + j + 1;
      GLuint bottomLeft = (i + 1) * (cols + 1) + j;
      GLuint bottomRight = (i + 1) * (cols + 1) + j + 1;
      indicesData[idx++] = topLeft;
      indicesData[idx++] = topRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = topLeft;
    }
  }

  _triangularIndices = [LTIndicesData dataWithIntegerIndices:indicesData];
}

+ (LTGPUStruct *)vertexStruct {
  return [[LTGPUStructRegistry sharedInstance] structForName:@"LTRegularGridMeshVertex"];
}

- (LTIndicesData *)wireframeIndices {
  if (!_wireframeIndices) {
    [self createWireframeIndices];
  }
  return _wireframeIndices;
}

- (void)createWireframeIndices {
  GLuint cols = self.size.width;
  GLuint rows = self.size.height;
  std::vector<GLuint> indicesData(rows * cols * 8);
  for (GLuint i = 0, idx = 0; i < rows; ++i) {
    for (GLuint j = 0; j < cols; ++j) {
      GLuint topLeft = i * (cols + 1) + j;
      GLuint topRight = i * (cols + 1) + j + 1;
      GLuint bottomLeft = (i + 1) * (cols + 1) + j;
      GLuint bottomRight = (i + 1) * (cols + 1) + j + 1;
      indicesData[idx++] = topLeft;
      indicesData[idx++] = topRight;
      indicesData[idx++] = topRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomRight;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = bottomLeft;
      indicesData[idx++] = topLeft;
    }
  }

  _wireframeIndices = [LTIndicesData dataWithIntegerIndices:indicesData];
}

@end

NS_ASSUME_NONNULL_END
