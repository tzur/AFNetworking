// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadMapping.h"

#import "LTQuad.h"

GLKMatrix3 LTTextureMatrix3ForQuad(LTQuad *quad, CGSize textureSize) {
  GLKMatrix3 scale = GLKMatrix3MakeScale(1 / textureSize.width, 1 / textureSize.height, 1);
  return GLKMatrix3Multiply(scale, LTMatrix3ForQuad(quad));
}

GLKMatrix3 LTMatrix3ForQuad(LTQuad *quad) {
  return GLKMatrix3Transpose(quad.transform);
}

GLKMatrix4 LTMatrix4ForQuad(LTQuad *quad) {
  GLKMatrix3 matrix3D = LTMatrix3ForQuad(quad);
  return GLKMatrix4Make(matrix3D.m00, matrix3D.m01, 0, matrix3D.m02,
                        matrix3D.m10, matrix3D.m11, 0, matrix3D.m12,
                        0, 0, 1, 0,
                        matrix3D.m20, matrix3D.m21, 0, matrix3D.m22);
}
