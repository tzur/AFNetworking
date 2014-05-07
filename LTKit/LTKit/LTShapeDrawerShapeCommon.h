// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGPUStruct.h"

LTGPUStructDeclare(LTShapeDrawerVertex,
                   GLKVector2, position,
                   GLKVector2, offset,
                   GLKVector4, lineBounds,
                   GLKVector4, shadowBounds,
                   GLKVector4, color,
                   GLKVector4, shadowColor);

/// Rectangular segment consisting of four vertices, used to generate two triangles for drawing it.
typedef union {
  struct { LTShapeDrawerVertex src0, src1, dst0, dst1; };
  LTShapeDrawerVertex v[4];
} LTShapeDrawerSegment;

typedef std::vector<LTShapeDrawerVertex> LTShapeDrawerVertices;

/// Adds the given vertex, with a clear stroke/fill color, to the vector of shadow vertices.
void LTAddShadowVertex(const LTShapeDrawerVertex &vertex, LTShapeDrawerVertices *shadowVertices);

/// Adds the given vertex, with a clear shadow color, to the vector of stroke vertices.
void LTAddStrokeVertex(const LTShapeDrawerVertex &vertex, LTShapeDrawerVertices *strokeVertices);

/// Adds the given segment to the vectors of stroke vertices and shadow vertices (if not nil).
void LTAddSegment(const LTShapeDrawerSegment &segment, LTShapeDrawerVertices *strokeVertices,
                  LTShapeDrawerVertices *shadowVertices);
