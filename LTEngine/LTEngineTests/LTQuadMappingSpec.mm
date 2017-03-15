// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadMapping.h"

#import "LTGLKitExtensions.h"
#import "LTQuad.h"

static GLKVector4 LTGLKVector3To4(GLKVector3 vec) {
  return GLKVector4Make(vec.x, vec.y, 0, vec.z);
}

SpecBegin(LTQuadMapping)

static const double kEpsilon = 1e-8;

static const GLKVector3 kTopLeft = GLKVector3Make(0, 0, 1);
static const GLKVector3 kTopRight = GLKVector3Make(1, 0, 1);
static const GLKVector3 kBottomLeft = GLKVector3Make(0, 1, 1);
static const GLKVector3 kBottomRight = GLKVector3Make(1, 1, 1);

static const CGSize kSize = CGSizeMake(8, 12);

static const CGPoint kQuadTopLeft = CGPointMake(0, 0);
static const CGPoint kQuadTopRight = CGPointMake(1, 0);
static const CGPoint kQuadBottomLeft = CGPointMake(0, 1);
static const CGPoint kQuadBottomRight = CGPointMake(1, 0.9);

__block LTQuad *quad;
__block GLKVector3 expectedTopLeft;
__block GLKVector3 expectedTopRight;
__block GLKVector3 expectedBottomRight;
__block GLKVector3 expectedBottomLeft;

beforeAll(^{
  LTQuadCorners corners{{kQuadTopLeft, kQuadTopRight, kQuadBottomRight, kQuadBottomLeft}};
  quad = [[LTQuad alloc] initWithCorners:corners];
});

context(@"mapping of canonical square to normalized quad", ^{
  beforeEach(^{
    expectedTopLeft = GLKVector3Make(kQuadTopLeft.x / kSize.width,
                                     kQuadTopLeft.y / kSize.height, 1);
    expectedTopRight = GLKVector3Make(kQuadTopRight.x / kSize.width,
                                      kQuadTopRight.y / kSize.height, 1);
    expectedBottomLeft = GLKVector3Make(kQuadBottomLeft.x / kSize.width,
                                        kQuadBottomLeft.y / kSize.height, 1);
    expectedBottomRight = GLKVector3Make(kQuadBottomRight.x / kSize.width,
                                         kQuadBottomRight.y / kSize.height, 1);
  });

  it(@"should compute the correct three-dimensional matrix for texture mapping", ^{
    GLKMatrix3 matrix = LTTextureMatrix3ForQuad(quad, kSize);

    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, kTopLeft);
    actualTopLeft = actualTopLeft / actualTopLeft.z;
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, kTopRight);
    actualTopRight = actualTopRight / actualTopRight.z;
    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, kBottomLeft);
    actualBottomLeft = actualBottomLeft / actualBottomLeft.z;
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, kBottomRight);
    actualBottomRight = actualBottomRight / actualBottomRight.z;

    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });

  it(@"should compute three-dimensional matrix mapping canonical square to normalized quad", ^{
    GLKMatrix3 matrix = LTMatrix3ForNormalizedQuad(quad.quad, kSize);

    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, kTopLeft);
    actualTopLeft = actualTopLeft / actualTopLeft.z;
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, kTopRight);
    actualTopRight = actualTopRight / actualTopRight.z;
    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, kBottomLeft);
    actualBottomLeft = actualBottomLeft / actualBottomLeft.z;
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, kBottomRight);
    actualBottomRight = actualBottomRight / actualBottomRight.z;

    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });
});

context(@"mapping of canonical square to quad", ^{
  beforeEach(^{
    expectedTopRight = GLKVector3Make(kQuadTopRight.x, kQuadTopRight.y, 1);
    expectedTopLeft = GLKVector3Make(kQuadTopLeft.x, kQuadTopLeft.y, 1);
    expectedBottomLeft = GLKVector3Make(kQuadBottomLeft.x, kQuadBottomLeft.y, 1);
    expectedBottomRight = GLKVector3Make(kQuadBottomRight.x, kQuadBottomRight.y, 1);
  });

  it(@"should compute the correct three-dimensional matrix", ^{
    GLKMatrix3 matrix = LTMatrix3ForQuad(quad);

    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, kTopLeft);
    actualTopLeft = actualTopLeft / actualTopLeft.z;
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, kTopRight);
    actualTopRight = actualTopRight / actualTopRight.z;
    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, kBottomLeft);
    actualBottomLeft = actualBottomLeft / actualBottomLeft.z;
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, kBottomRight);
    actualBottomRight = actualBottomRight / actualBottomRight.z;

    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });

  it(@"should compute three-dimensional matrix mapping canonical square to quad", ^{
    GLKMatrix3 matrix = LTMatrix3ForQuad(quad.quad);

    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, kTopLeft);
    actualTopLeft = actualTopLeft / actualTopLeft.z;
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, kTopRight);
    actualTopRight = actualTopRight / actualTopRight.z;
    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, kBottomLeft);
    actualBottomLeft = actualBottomLeft / actualBottomLeft.z;
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, kBottomRight);
    actualBottomRight = actualBottomRight / actualBottomRight.z;

    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });
});

context(@"mapping of canonical square to quad", ^{
  __block GLKVector4 expectedTopRight;
  __block GLKVector4 expectedTopLeft;
  __block GLKVector4 expectedBottomLeft;
  __block GLKVector4 expectedBottomRight;

  beforeEach(^{
    expectedTopRight = GLKVector4Make(kQuadTopRight.x, kQuadTopRight.y, 0, 1);
    expectedTopLeft = GLKVector4Make(kQuadTopLeft.x, kQuadTopLeft.y, 0, 1);
    expectedBottomLeft = GLKVector4Make(kQuadBottomLeft.x, kQuadBottomLeft.y, 0, 1);
    expectedBottomRight = GLKVector4Make(kQuadBottomRight.x, kQuadBottomRight.y, 0, 1);
  });

  it(@"should compute the correct four-dimensional matrix", ^{
    GLKMatrix4 matrix = LTMatrix4ForQuad(quad);

    GLKVector4 actualTopLeft = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kTopLeft));
    actualTopLeft = actualTopLeft / actualTopLeft.w;
    GLKVector4 actualTopRight = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kTopRight));
    actualTopRight = actualTopRight / actualTopRight.w;
    GLKVector4 actualBottomLeft = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kBottomLeft));
    actualBottomLeft = actualBottomLeft / actualBottomLeft.w;
    GLKVector4 actualBottomRight = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kBottomRight));
    actualBottomRight = actualBottomRight / actualBottomRight.w;

    expect(GLKVector4Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });

  it(@"should compute four-dimensional matrix mapping canonical square to quad", ^{
    GLKMatrix4 matrix = LTMatrix4ForQuad(quad.quad);

    GLKVector4 actualTopLeft = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kTopLeft));
    actualTopLeft = actualTopLeft / actualTopLeft.w;
    GLKVector4 actualTopRight = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kTopRight));
    actualTopRight = actualTopRight / actualTopRight.w;
    GLKVector4 actualBottomLeft = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kBottomLeft));
    actualBottomLeft = actualBottomLeft / actualBottomLeft.w;
    GLKVector4 actualBottomRight = GLKMatrix4MultiplyVector4(matrix, LTGLKVector3To4(kBottomRight));
    actualBottomRight = actualBottomRight / actualBottomRight.w;

    expect(GLKVector4Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kEpsilon);
    expect(GLKVector4Length(actualBottomRight - expectedBottomRight))
        .to.beCloseToWithin(0, kEpsilon);
  });
});

SpecEnd
