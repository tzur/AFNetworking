// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGPUStruct.h"

/// Struct used for vertices of the common drawable shape.
LTGPUStructDeclare(LTCommonDrawableShapeVertex,
                   LTVector2, position,
                   LTVector2, offset,
                   LTVector4, lineBounds,
                   LTVector4, shadowBounds,
                   LTVector4, color,
                   LTVector4, shadowColor);

/// Rectangular segment consisting of four vertices, used to generate two triangles for drawing it.
union LTCommonDrawableShapeSegment {
  LTCommonDrawableShapeSegment() {}

  struct {
    LTCommonDrawableShapeVertex src0, src1, dst0, dst1;
  };
  LTCommonDrawableShapeVertex v[4];
};

/// A collection of vertices of the common drawable shape.
typedef std::vector<LTCommonDrawableShapeVertex> LTCommonDrawableShapeVertices;

/// Adds the given vertex, with a clear stroke/fill color, to the vector of shadow vertices.
void LTAddShadowVertex(const LTCommonDrawableShapeVertex &vertex,
                       LTCommonDrawableShapeVertices *shadowVertices);

/// Adds the given vertex, with a clear shadow color, to the vector of stroke vertices.
void LTAddStrokeVertex(const LTCommonDrawableShapeVertex &vertex,
                       LTCommonDrawableShapeVertices *strokeVertices);

/// Adds the given segment to the vectors of stroke vertices and shadow vertices (if not nil).
void LTAddSegment(const LTCommonDrawableShapeSegment &segment,
                  LTCommonDrawableShapeVertices *strokeVertices,
                  LTCommonDrawableShapeVertices *shadowVertices);
