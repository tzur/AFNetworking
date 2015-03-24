// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCommonDrawableShapeStructs.h"

#import "LTGLKitExtensions.h"

void LTAddShadowVertex(const LTCommonDrawableShapeVertex &vertex,
                       LTCommonDrawableShapeVertices *shadowVertices) {
  LTParameterAssert(shadowVertices);
  shadowVertices->push_back(vertex);
  shadowVertices->back().color = LTVector4Zero;
}

void LTAddStrokeVertex(const LTCommonDrawableShapeVertex &vertex,
                       LTCommonDrawableShapeVertices *strokeVertices) {
  LTParameterAssert(strokeVertices);
  strokeVertices->push_back(vertex);
  strokeVertices->back().shadowColor = LTVector4Zero;
}

void LTAddSegment(const LTCommonDrawableShapeSegment &segment,
                  LTCommonDrawableShapeVertices *strokeVertices,
                  LTCommonDrawableShapeVertices *shadowVertices) {
  LTParameterAssert(strokeVertices);
  if (shadowVertices) {
    LTAddShadowVertex(segment.src0, shadowVertices);
    LTAddShadowVertex(segment.src1, shadowVertices);
    LTAddShadowVertex(segment.dst0, shadowVertices);
    LTAddShadowVertex(segment.src1, shadowVertices);
    LTAddShadowVertex(segment.dst1, shadowVertices);
    LTAddShadowVertex(segment.dst0, shadowVertices);
  }
  LTAddStrokeVertex(segment.src0, strokeVertices);
  LTAddStrokeVertex(segment.src1, strokeVertices);
  LTAddStrokeVertex(segment.dst0, strokeVertices);
  LTAddStrokeVertex(segment.src1, strokeVertices);
  LTAddStrokeVertex(segment.dst1, strokeVertices);
  LTAddStrokeVertex(segment.dst0, strokeVertices);
}
