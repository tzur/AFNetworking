// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectMapping.h"

#import "LTGLKitExtensions.h"
#import "LTRotatedRect.h"

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
  const double kRange = 1e-4;

  it(@"should create correct matrix 3 texture mapping", ^{
    LTRotatedRect *rect = [LTRotatedRect rect:CGRectMake(1, 2, 3, 4) withAngle:M_PI];
    CGSize textureSize = CGSizeMake(8, 12);
    GLKMatrix3 matrix = LTTextureMatrix3ForRotatedRect(rect, textureSize);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    GLKVector3 expectedBottomLeft = GLKVector3Make(4 / textureSize.width, 6 / textureSize.height, 1);
    GLKVector3 expectedBottomRight = GLKVector3Make(1 / textureSize.width, 6 / textureSize.height, 1);
    GLKVector3 expectedTopLeft = GLKVector3Make(4 / textureSize.width, 2 / textureSize.height, 1);
    GLKVector3 expectedTopRight = GLKVector3Make(1 / textureSize.width, 2 / textureSize.height, 1);

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
    LTRotatedRect *rect = [LTRotatedRect rect:CGRectMake(1, 2, 3, 4) withAngle:M_PI];
    GLKMatrix3 matrix = LTMatrix3ForRotatedRect(rect);

    GLKVector3 bottomLeft = GLKVector3Make(0, 0, 1);
    GLKVector3 bottomRight = GLKVector3Make(1, 0, 1);
    GLKVector3 topLeft = GLKVector3Make(0, 1, 1);
    GLKVector3 topRight = GLKVector3Make(1, 1, 1);

    GLKVector3 expectedBottomLeft = GLKVector3Make(4, 6, 1);
    GLKVector3 expectedBottomRight = GLKVector3Make(1, 6, 1);
    GLKVector3 expectedTopLeft = GLKVector3Make(4, 2, 1);
    GLKVector3 expectedTopRight = GLKVector3Make(1, 2, 1);

    GLKVector3 actualBottomLeft = GLKMatrix3MultiplyVector3(matrix, bottomLeft);
    GLKVector3 actualBottomRight = GLKMatrix3MultiplyVector3(matrix, bottomRight);
    GLKVector3 actualTopLeft = GLKMatrix3MultiplyVector3(matrix, topLeft);
    GLKVector3 actualTopRight = GLKMatrix3MultiplyVector3(matrix, topRight);

    expect(GLKVector3Length(actualBottomLeft - expectedBottomLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualBottomRight - expectedBottomRight)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopLeft - expectedTopLeft)).to.beCloseToWithin(0, kRange);
    expect(GLKVector3Length(actualTopRight - expectedTopRight)).to.beCloseToWithin(0, kRange);
  });

  it(@"should create correct matrix 4 mapping", ^{
    LTRotatedRect *rect = [LTRotatedRect rect:CGRectMake(1, 2, 3, 4) withAngle:M_PI];
    GLKMatrix4 matrix = LTMatrix4ForRotatedRect(rect);

    GLKVector4 bottomLeft = GLKVector4Make(0, 0, 0, 1);
    GLKVector4 bottomRight = GLKVector4Make(1, 0, 0, 1);
    GLKVector4 topLeft = GLKVector4Make(0, 1, 0, 1);
    GLKVector4 topRight = GLKVector4Make(1, 1, 0, 1);

    GLKVector4 expectedBottomLeft = GLKVector4Make(4, 6, 0, 1);
    GLKVector4 expectedBottomRight = GLKVector4Make(1, 6, 0, 1);
    GLKVector4 expectedTopLeft = GLKVector4Make(4, 2, 0, 1);
    GLKVector4 expectedTopRight = GLKVector4Make(1, 2, 0, 1);

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
