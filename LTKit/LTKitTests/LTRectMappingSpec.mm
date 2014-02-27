// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectMapping.h"

#import "LTGLKitExtensions.h"
#import "LTRotatedRect.h"

static GLKVector4 LTGLKVector3To4(GLKVector3 vec) {
  return GLKVector4Make(vec.x, vec.y, 0, vec.z);
}

SpecBegin(LTRectMapping)

context(@"rect", ^{
  it(@"should craete correct matrix 3 texture mapping", ^{
    CGRect rect = CGRectMake(1, 2, 3, 4);
    CGSize textureSize = CGSizeMake(8, 12);
    GLKMatrix3 matrix = LTTextureMatrix3ForRect(rect, textureSize);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    GLKVector3 expectedBottomLeft = GLKVector3Make(1 / textureSize.width,
                                                   2 / textureSize.height, 1);
    GLKVector3 expectedBottomRight = GLKVector3Make(4 / textureSize.width,
                                                    2 / textureSize.height, 1);
    GLKVector3 expectedTopLeft = GLKVector3Make(1 / textureSize.width, 6 / textureSize.height, 1);
    GLKVector3 expectedTopRight = GLKVector3Make(4 / textureSize.width, 6 / textureSize.height, 1);

    expect(GLKMatrix3MultiplyVector3(matrix, bottomLeft) == expectedBottomLeft).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, bottomRight) == expectedBottomRight).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, topLeft) == expectedTopLeft).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, topRight) == expectedTopRight).to.beTruthy();
  });

  it(@"should create correct matrix 3 mapping", ^{
    CGRect rect = CGRectMake(1, 2, 3, 4);
    GLKMatrix3 matrix = LTMatrix3ForRect(rect);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    expect(GLKMatrix3MultiplyVector3(matrix, bottomLeft) == GLKVector3Make(1, 2, 1)).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, bottomRight) == GLKVector3Make(4, 2, 1)).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, topLeft) == GLKVector3Make(1, 6, 1)).to.beTruthy();
    expect(GLKMatrix3MultiplyVector3(matrix, topRight) == GLKVector3Make(4, 6, 1)).to.beTruthy();
  });

  it(@"should create correct matrix 4 mapping", ^{
    CGRect rect = CGRectMake(1, 2, 3, 4);
    GLKMatrix4 matrix = LTMatrix4ForRect(rect);

    GLKVector4 bottomLeft = GLKVector4Make(0, 0, 0, 1);
    GLKVector4 bottomRight = GLKVector4Make(1, 0, 0, 1);
    GLKVector4 topLeft = GLKVector4Make(0, 1, 0, 1);
    GLKVector4 topRight = GLKVector4Make(1, 1, 0, 1);

    expect(GLKMatrix4MultiplyVector4(matrix, bottomLeft)).to.equal(GLKVector4Make(1, 2, 0, 1));
    expect(GLKMatrix4MultiplyVector4(matrix, bottomRight)).to.equal(GLKVector4Make(4, 2, 0, 1));
    expect(GLKMatrix4MultiplyVector4(matrix, topLeft)).to.equal(GLKVector4Make(1, 6, 0, 1));
    expect(GLKMatrix4MultiplyVector4(matrix, topRight)).to.equal(GLKVector4Make(4, 6, 0, 1));
  });
});

context(@"rotated rect", ^{
  LTRotatedRect * const kRect = [LTRotatedRect rect:CGRectMake(1, 2, 3, 4) withAngle:M_PI_4];

  const GLKVector3 kBottomLeft = GLKVector3Make(2.8535533, 1.52512646, 1);
  const GLKVector3 kBottomRight = GLKVector3Make(4.97487354, 3.6464467, 1);
  const GLKVector3 kTopLeft = GLKVector3Make(0.0251262188, 4.35355377, 1);
  const GLKVector3 kTopRight = GLKVector3Make(2.14644647, 6.47487354, 1);

  const double kRange = 1e-4;
  
  it(@"should create correct matrix 3 texture mapping", ^{
    CGSize textureSize = CGSizeMake(8, 12);
    GLKMatrix3 matrix = LTTextureMatrix3ForRotatedRect(kRect, textureSize);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    GLKVector3 expectedBottomLeft = GLKVector3Make(kBottomLeft.x / textureSize.width,
                                                   kBottomLeft.y / textureSize.height, 1);
    GLKVector3 expectedBottomRight = GLKVector3Make(kBottomRight.x / textureSize.width,
                                                    kBottomRight.y / textureSize.height, 1);
    GLKVector3 expectedTopLeft = GLKVector3Make(kTopLeft.x / textureSize.width,
                                                kTopLeft.y / textureSize.height, 1);
    GLKVector3 expectedTopRight = GLKVector3Make(kTopRight.x / textureSize.width,
                                                 kTopRight.y / textureSize.height, 1);

    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, bottomLeft);
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, bottomRight);
    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, topLeft);
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, topRight);

    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kRange);
  });

  it(@"should create correct matrix 3 mapping", ^{
    GLKMatrix3 matrix = LTMatrix3ForRotatedRect(kRect);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, bottomLeft);
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, bottomRight);
    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, topLeft);
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, topRight);

    expect(GLKVector3Length(actualBottomLeft - kBottomLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualBottomRight - kBottomRight)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopLeft - kTopLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopRight - kTopRight)).to.beCloseToWithin(0, kRange);
  });

  it(@"should create correct matrix 4 mapping", ^{
    GLKMatrix4 matrix = LTMatrix4ForRotatedRect(kRect);

    GLKVector4 bottomLeft = GLKVector4Make(0, 0, 0, 1);
    GLKVector4 bottomRight = GLKVector4Make(1, 0, 0, 1);
    GLKVector4 topLeft = GLKVector4Make(0, 1, 0, 1);
    GLKVector4 topRight = GLKVector4Make(1, 1, 0, 1);

    GLKVector4 expectedBottomLeft = LTGLKVector3To4(kBottomLeft);
    GLKVector4 expectedBottomRight = LTGLKVector3To4(kBottomRight);
    GLKVector4 expectedTopLeft = LTGLKVector3To4(kTopLeft);
    GLKVector4 expectedTopRight = LTGLKVector3To4(kTopRight);

    GLKVector4 actualBottomLeft = GLKMatrix4MultiplyVector4(matrix, bottomLeft);
    GLKVector4 actualBottomRight = GLKMatrix4MultiplyVector4(matrix, bottomRight);
    GLKVector4 actualTopLeft = GLKMatrix4MultiplyVector4(matrix, topLeft);
    GLKVector4 actualTopRight = GLKMatrix4MultiplyVector4(matrix, topRight);

    expect(GLKVector4Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector4Length(actualBottomRight - expectedBottomRight)).to.beCloseToWithin(0, kRange);
    expect(GLKVector4Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector4Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kRange);
  });
});

SpecEnd
