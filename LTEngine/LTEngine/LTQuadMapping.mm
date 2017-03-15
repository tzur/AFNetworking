// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadMapping.h"

GLKMatrix3 LTMatrix3ForNormalizedQuad(const lt::Quad &quad, CGSize size) {
  GLKMatrix3 scale = GLKMatrix3MakeScale(1 / size.width, 1 / size.height, 1);
  return GLKMatrix3Multiply(scale, LTMatrix3ForQuad(quad));
}

GLKMatrix3 LTMatrix3ForQuad(const lt::Quad &quad) {
  return GLKMatrix3Transpose(quad.transform());
}

GLKMatrix3 LTInvertedMatrix3ForQuad(const lt::Quad &quad, CGSize size) {
  bool invertible;
  GLKMatrix3 result =
      GLKMatrix3Multiply(GLKMatrix3Invert(LTMatrix3ForQuad(quad), &invertible),
                         GLKMatrix3MakeScale(size.width, size.height, 1));
  if (!invertible) {
    result = GLKMatrix3Make(0, 0, 0, 0, 0, 0, 0, 0, 0);
  }
  return result;
}

GLKMatrix4 LTMatrix4ForQuad(const lt::Quad &quad) {
  GLKMatrix3 matrix3D = LTMatrix3ForQuad(quad);
  return GLKMatrix4Make(matrix3D.m00, matrix3D.m01, 0, matrix3D.m02,
                        matrix3D.m10, matrix3D.m11, 0, matrix3D.m12,
                        0, 0, 1, 0,
                        matrix3D.m20, matrix3D.m21, 0, matrix3D.m22);
}
