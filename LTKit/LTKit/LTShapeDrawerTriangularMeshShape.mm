// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerTriangularMeshShape.h"

#import "LTArrayBuffer.h"
#import "LTCGExtensions.h"
#import "LTDrawingContext.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTShapeDrawerTriangularMeshShapeVsh.h"
#import "LTShaderStorage+LTShapeDrawerTriangularMeshShapeFsh.h"
#import "LTShapeDrawerParams.h"
#import "LTVertexArray.h"

/// Struct used for vertices of the triangular mesh.
LTGPUStructMake(LTShapeDrawerTriangularMeshShapeVertex,
                GLKVector2, position,
                GLKVector4, shadowMaskAndWidth,
                GLKVector3, barycentric,
                GLKVector3, edge01,
                GLKVector3, edge12,
                GLKVector3, edge20,
                GLKVector4, color,
                GLKVector4, shadowColor);

/// Struct used to hold three GPU vertices of the triangular mesh.
typedef union {
  struct { LTShapeDrawerTriangularMeshShapeVertex v0, v1, v2; };
  LTShapeDrawerTriangularMeshShapeVertex v[3];
} LTShapeDrawerTriangle;

/// A collection of \c LTShapeDrawerTriangles.
typedef std::vector<LTShapeDrawerTriangle> LTShapeDrawerTriangles;

/// Struct holding the edge equations of a \c CGTriangle edges.
typedef union {
  struct { GLKVector3 ab, bc, ca; };
  GLKVector3 e[3];
} CGTriangleEdges;

@interface LTShapeDrawerTriangularMeshShape () {
  LTShapeDrawerTriangles _filledTriangles;
  LTShapeDrawerTriangles _shadowTriangles;
}

/// Vertices used for filling the shape.
@property (readonly, nonatomic) LTShapeDrawerTriangles &filledTriangles;

/// Vertices used for drawing the shadow around the shape.
@property (readonly, nonatomic) LTShapeDrawerTriangles &shadowTriangles;

@end

@implementation LTShapeDrawerTriangularMeshShape

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShapeDrawerTriangularMeshShapeVsh source]
                                  fragmentSource:[LTShapeDrawerTriangularMeshShapeFsh source]];
}

- (NSString *)vertexShaderStructName {
  return @"LTShapeDrawerTriangularMeshShapeVertex";
}

- (NSArray *)vertexShaderAttributes {
  return @[@"position", @"barycentric", @"shadowMaskAndWidth", @"edge01", @"edge12", @"edge20",
           @"color", @"shadowColor"];
}

#pragma mark -
#pragma mark Triangles
#pragma mark -

- (void)fillTriangle:(CGTriangle)triangle withShadowOnEdges:(CGTriangleEdgeMask)edgeMask {
  // Calculate the edge equations, and return in case the triangle is degenerate.
  CGTriangleEdges edges = [self edgesFromTriangle:triangle];
  if (edges.ab == GLKVector3Zero || edges.bc == GLKVector3Zero || edges.ca == GLKVector3Zero) {
    return;
  }

  // In case the triangle is given in clockwise order, convert it to a counter clockwise order.
  BOOL clockwise =
      GLKVector3DotProduct(GLKVector3Make(triangle.a.x, triangle.a.y, 1), edges.bc) > 0;
  if (clockwise) {
    triangle = CGTriangleMake(triangle.a, triangle.c, triangle.b);
    CGTriangleEdgeMask newMask = CGTriangleEdgeNone;
    newMask |= (edgeMask & CGTriangleEdgeAB) ? CGTriangleEdgeCA : CGTriangleEdgeNone;
    newMask |= (edgeMask & CGTriangleEdgeBC) ? CGTriangleEdgeBC : CGTriangleEdgeNone;
    newMask |= (edgeMask & CGTriangleEdgeCA) ? CGTriangleEdgeAB : CGTriangleEdgeNone;
    edges = [self edgesFromTriangle:triangle];
    edgeMask = newMask;
  }
  
  // Expand the triangle (to include room for the shadows), and generate its vertices.
  triangle = [self expandedTriangleFromEdges:edges];
  LTShapeDrawerTriangle vertices =
      [self verticesForTriangle:triangle edges:edges edgeMask:edgeMask];;
  self.filledTriangles.push_back(vertices);
}

- (CGTriangleEdges)edgesFromTriangle:(const CGTriangle &)triangle {
  return {
    .ab = GLKLineEquation(triangle.a, triangle.b),
    .bc = GLKLineEquation(triangle.b, triangle.c),
    .ca = GLKLineEquation(triangle.c, triangle.a)
  };
}

- (CGTriangle)expandedTriangleFromEdges:(CGTriangleEdges)edges {
  for (GLKVector3 &edge : edges.e) {
    GLKVector2 normal = GLKVector2Normalize(GLKVector2Make(edge.x, edge.y));
    edge.z -= self.params.shadowWidth * (edge.x * normal.x + edge.y * normal.y);
  }
  GLKVector3 a = GLKVector3CrossProduct(edges.ab, edges.ca);
  GLKVector3 b = GLKVector3CrossProduct(edges.ab, edges.bc);
  GLKVector3 c = GLKVector3CrossProduct(edges.bc, edges.ca);
  a = a / (a.z ?: 1);
  b = b / (b.z ?: 1);
  c = c / (c.z ?: 1);
  return CGTriangleMake(CGPointMake(a.x, a.y), CGPointMake(b.x, b.y), CGPointMake(c.x, c.y));
}

- (LTShapeDrawerTriangle)verticesForTriangle:(const CGTriangle &)triangle
                                       edges:(const CGTriangleEdges &)edges
                                    edgeMask:(const CGTriangleEdgeMask &)mask {
  LTShapeDrawerTriangle vertices;
  for (LTShapeDrawerTriangularMeshShapeVertex &vertex : vertices.v) {
    vertex.edge01 = edges.ab;
    vertex.edge12 = edges.bc;
    vertex.edge20 = edges.ca;
    vertex.color = (GLKVector4)self.params.fillColor;
    vertex.shadowColor = (GLKVector4)self.params.shadowColor;
    vertex.shadowMaskAndWidth = GLKVector4Make(mask & CGTriangleEdgeAB ? 1.0 : 0.0,
                                               mask & CGTriangleEdgeBC ? 1.0 : 0.0,
                                               mask & CGTriangleEdgeCA ? 1.0 : 0.0,
                                               self.params.shadowWidth);
  }
  vertices.v0.barycentric = GLKVector3Make(1, 0, 0);
  vertices.v1.barycentric = GLKVector3Make(0, 1, 0);
  vertices.v2.barycentric = GLKVector3Make(0, 0, 1);
  vertices.v0.position = GLKVector2FromCGPoint(triangle.a);
  vertices.v1.position = GLKVector2FromCGPoint(triangle.b);
  vertices.v2.position = GLKVector2FromCGPoint(triangle.c);
  return vertices;
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawInFramebufferWithSize:(CGSize)size {
  if ([LTGLContext currentContext].renderingToScreen) {
    [self setProjectionForScreenFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:YES];
  } else {
    [self setProjectionForFramebufferWithSize:size];
    [self drawWithClockwiseFrontFacingPolygons:NO];
  }
}

- (void)drawWithClockwiseFrontFacingPolygons:(BOOL)cwffPolygons {
  [self updateBuffer];
  [self setUniforms];
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.clockwiseFrontFacingPolygons = cwffPolygons;
    [self.context drawWithMode:LTDrawingContextDrawModeTriangles];
  }];
}

- (void)setUniforms {
  GLKMatrix4 modelview =
      GLKMatrix4Rotate(GLKMatrix4MakeTranslation(self.translation.x, self.translation.y, 0),
                       self.rotationAngle, 0, 0, 1);
  
  self.program[[LTShapeDrawerTriangularMeshShapeVsh modelview]] = $(modelview);
  self.program[[LTShapeDrawerTriangularMeshShapeFsh opacity]] = @(self.opacity);
}

- (void)setProjectionForFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, 0, size.height, -1, 1);
  self.program[[LTShapeDrawerTriangularMeshShapeVsh projection]] = $(projection);
}

- (void)setProjectionForScreenFramebufferWithSize:(CGSize)size {
  GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, size.width, size.height, 0, -1, 1);
  self.program[[LTShapeDrawerTriangularMeshShapeVsh projection]] = $(projection);
}

- (void)updateBuffer {
  NSMutableArray *dataArray = [NSMutableArray array];
  if (!self.shadowTriangles.empty()) {
    [dataArray addObject:
        [NSData dataWithBytesNoCopy:&self.shadowTriangles[0]
                             length:self.shadowTriangles.size() * sizeof(LTShapeDrawerTriangle)
                       freeWhenDone:NO]];
  }
  if (!self.filledTriangles.empty()) {
    [dataArray addObject:
        [NSData dataWithBytesNoCopy:&self.filledTriangles[0]
                             length:self.filledTriangles.size() * sizeof(LTShapeDrawerTriangle)
                       freeWhenDone:NO]];
  }
  [self.arrayBuffer setDataWithConcatenatedData:dataArray];
}

@end
