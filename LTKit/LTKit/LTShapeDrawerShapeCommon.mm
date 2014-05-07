// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerShapeCommon.h"

#import "LTGLKitExtensions.mm"

void LTAddShadowVertex(const LTShapeDrawerVertex &vertex, LTShapeDrawerVertices *shadowVertices) {
  LTParameterAssert(shadowVertices);
  shadowVertices->push_back(vertex);
  shadowVertices->back().color = GLKVector4Zero;
}

void LTAddStrokeVertex(const LTShapeDrawerVertex &vertex, LTShapeDrawerVertices *strokeVertices) {
  LTParameterAssert(strokeVertices);
  strokeVertices->push_back(vertex);
  strokeVertices->back().shadowColor = GLKVector4Zero;
}

void LTAddSegment(const LTShapeDrawerSegment &segment, LTShapeDrawerVertices *strokeVertices,
                LTShapeDrawerVertices *shadowVertices) {
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
