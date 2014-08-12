// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLKitExtensions.h"

#import "UIColor+Vector.h"

SpecBegin(LTGLKitExtensions)

context(@"GLKMatrix2", ^{
  it(@"should make GLKMatrix2", ^{
    GLKMatrix2 m = GLKMatrix2Make(1, 2, 3, 4);

    expect(m.m00).to.equal(1);
    expect(m.m01).to.equal(2);
    expect(m.m10).to.equal(3);
    expect(m.m11).to.equal(4);
  });

  it(@"equal", ^{
    GLKMatrix2 a = {{1, 2, 3, 4}};
    GLKMatrix2 b = {{4, 3, 2, 1}};
    GLKMatrix2 c = {{1, 2, 3, 4}};

    expect(a == b).to.beFalsy();
    expect(a == c).to.beTruthy();
  });

  it(@"not equal", ^{
    GLKMatrix2 a = {{1, 2, 3, 4}};
    GLKMatrix2 b = {{4, 3, 2, 1}};
    GLKMatrix2 c = {{1, 2, 3, 4}};
    
    expect(a != b).to.beTruthy();
    expect(a != c).to.beFalsy();
  });
  
  it(@"should make rotation matrix", ^{
    GLKMatrix2 m = GLKMatrix2MakeRotation(M_PI_4);

    expect(m.m00).to.beCloseTo(1 / sqrt(2));
    expect(m.m10).to.beCloseTo(-1 / sqrt(2));
    expect(m.m01).to.beCloseTo(1 / sqrt(2));
    expect(m.m11).to.beCloseTo(1 / sqrt(2));
  });
  
  it(@"should make scale matrix", ^{
    GLKMatrix2 m = GLKMatrix2MakeScale(3, -2);
    expect(m.m00).to.beCloseTo(3);
    expect(m.m10).to.equal(0);
    expect(m.m01).to.equal(0);
    expect(m.m11).to.beCloseTo(-2);
  });

  it(@"should multiply matrixs correctly", ^{
    GLKMatrix2 m1 = {{1, 2, 3, 4}};
    GLKMatrix2 m2 = {{5, 6, 7, 8}};
    
    expect(GLKMatrix2Multiply(m1, m2) == GLKMatrix2Make(23, 34, 31, 46)).to.beTruthy();
  });
  
  it(@"should multiply vector correctly", ^{
    GLKMatrix2 m = {{1, 2, 3, 4}};
    GLKVector2 v = {{1, 2}};

    expect(GLKMatrix2MultiplyVector2(m, v) == GLKVector2Make(7, 10)).to.beTruthy();
  });
});

context(@"GLKMatrix3", ^{
  it(@"should transpose matrix", ^{
    GLKMatrix3 m = GLKMatrix3Make(1, 2, 3,
                                  4, 5, 6,
                                  7, 8, 9);
    GLKMatrix3 transposed = GLKMatrix3Transpose(m);

    expect(transposed.m00).to.equal(1);
    expect(transposed.m10).to.equal(2);
    expect(transposed.m20).to.equal(3);
    expect(transposed.m01).to.equal(4);
    expect(transposed.m11).to.equal(5);
    expect(transposed.m21).to.equal(6);
    expect(transposed.m02).to.equal(7);
    expect(transposed.m12).to.equal(8);
    expect(transposed.m22).to.equal(9);
  });

  it(@"should make translation matrix", ^{
    GLKMatrix3 m = GLKMatrix3MakeTranslation(1, 2);

    expect(m.m00).to.equal(1);
    expect(m.m01).to.equal(0);
    expect(m.m02).to.equal(0);
    expect(m.m10).to.equal(0);
    expect(m.m11).to.equal(1);
    expect(m.m12).to.equal(0);
    expect(m.m20).to.equal(1);
    expect(m.m21).to.equal(2);
    expect(m.m22).to.equal(1);
  });

  it(@"equal", ^{
    GLKMatrix3 a = {{1, 2, 3, 4, 5, 6, 7, 8, 9}};
    GLKMatrix3 b = {{9, 8, 7, 6, 5, 4, 3, 2, 1}};
    GLKMatrix3 c = {{1, 2, 3, 4, 5, 6, 7, 8, 9}};

    expect(a == b).to.beFalsy();
    expect(a == c).to.beTruthy();
  });
  
  it(@"not equal", ^{
    GLKMatrix3 a = {{1, 2, 3, 4, 5, 6, 7, 8, 9}};
    GLKMatrix3 b = {{9, 8, 7, 6, 5, 4, 3, 2, 1}};
    GLKMatrix3 c = {{1, 2, 3, 4, 5, 6, 7, 8, 9}};
    
    expect(a != b).to.beTruthy();
    expect(a != c).to.beFalsy();
  });
});

context(@"GLKMatrix4", ^{
  it(@"equal", ^{
    GLKMatrix4 a = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}};
    GLKMatrix4 b = {{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}};
    GLKMatrix4 c = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}};

    expect(a == b).to.beFalsy();
    expect(a == c).to.beTruthy();
  });
  
  it(@"not equal", ^{
    GLKMatrix4 a = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}};
    GLKMatrix4 b = {{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}};
    GLKMatrix4 c = {{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}};
    
    expect(a != b).to.beTruthy();
    expect(a != c).to.beFalsy();
  });
});

context(@"GLKVector2 operations", ^{
  it(@"equal", ^{
    expect(GLKVector2Make(1, 2) == GLKVector2Make(1, 2)).to.beTruthy();
    expect(GLKVector2Make(1, 2) == GLKVector2Make(-1, 2)).to.beFalsy();
    expect(GLKVector2Make(1, 2) == GLKVector2Make(1, -2)).to.beFalsy();
  });

  it(@"not equal", ^{
    expect(GLKVector2Make(1, 2) != GLKVector2Make(1, 2)).to.beFalsy();
    expect(GLKVector2Make(1, 2) != GLKVector2Make(-1, 2)).to.beTruthy();
    expect(GLKVector2Make(1, 2) != GLKVector2Make(1, -2)).to.beTruthy();
  });

  it(@"add", ^{
    expect(GLKVector2Make(1, 2) + GLKVector2Make(3, 4) == GLKVector2Make(4, 6)).to.beTruthy();
  });

  it(@"subtract", ^{
    expect(GLKVector2Make(5, 5) - GLKVector2Make(1, 2) == GLKVector2Make(4, 3)).to.beTruthy();
  });

  it(@"scalar multiply", ^{
    expect(GLKVector2Make(1, 2) * 2.f == GLKVector2Make(2, 4)).to.beTruthy();
    expect(2.f * GLKVector2Make(1, 2) == GLKVector2Make(2, 4)).to.beTruthy();
  });

  it(@"element-wise multiply", ^{
    expect(GLKVector2Make(1, 2) * GLKVector2Make(3, 4)).to.beCloseToGLKVector(GLKVector2Make(3, 8));
  });
  
  it(@"division", ^{
    expect(GLKVector2Make(2, 4) / 2.f == GLKVector2Make(1, 2)).to.beTruthy();
  });

  it(@"convert from cgpoint", ^{
    expect(GLKVector2FromCGPoint(CGPointMake(2, 4)) == GLKVector2Make(2, 4)).to.beTruthy();
  });

  it(@"floor", ^{
    GLKVector2 vec = GLKVector2Make(1.5, 2.7);
    expect(std::floor(vec) == GLKVector2Make(1, 2)).to.beTruthy();
  });
  
  it(@"round", ^{
    expect(std::round(GLKVector2Make(1.5, 2.7)) == GLKVector2Make(2, 3)).to.beTruthy();
  });
});

context(@"GLKVector3 operations", ^{
  it(@"equal", ^{
    expect(GLKVector3Make(1, 2, 3) == GLKVector3Make(1, 2, 3)).to.beTruthy();
    expect(GLKVector3Make(1, 2, 3) == GLKVector3Make(-1, 2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3) == GLKVector3Make(1, -2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3) == GLKVector3Make(1, 2, -3)).to.beFalsy();
  });

  it(@"not equal", ^{
    expect(GLKVector3Make(1, 2, 3) != GLKVector3Make(1, 2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3) != GLKVector3Make(-1, 2, 3)).to.beTruthy();
    expect(GLKVector3Make(1, 2, 3) != GLKVector3Make(1, -2, 3)).to.beTruthy();
    expect(GLKVector3Make(1, 2, 3) != GLKVector3Make(1, 2, -3)).to.beTruthy();
  });

  it(@"greater or equal", ^{
    expect(GLKVector3Make(1, 2, 3) <= GLKVector3Make(1, 2, 3)).to.beTruthy();
    expect(GLKVector3Make(1.1, 2, 3) <= GLKVector3Make(1, 2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2.1, 3) <= GLKVector3Make(1, 2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3.1) <= GLKVector3Make(1, 2, 3)).to.beFalsy();
    
    expect(GLKVector3Make(1, 2, 3) >= GLKVector3Make(1, 2, 3)).to.beTruthy();
    expect(GLKVector3Make(1, 2, 3) >= GLKVector3Make(1.1, 2, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3) >= GLKVector3Make(1, 2.1, 3)).to.beFalsy();
    expect(GLKVector3Make(1, 2, 3) >= GLKVector3Make(1, 2, 3.1)).to.beFalsy();
  });
  
  it(@"uniform", ^{
    expect(GLKVector3Make(1) == GLKVector3Make(1, 1, 1)).to.beTruthy();
    expect(GLKVector3Make(2) == GLKVector3Make(2, 2, 2)).to.beTruthy();
  });
  
  it(@"add", ^{
    expect(GLKVector3Make(1, 2, 3) + GLKVector3Make(4, 5, 6) ==
           GLKVector3Make(5, 7, 9)).to.beTruthy();
  });

  it(@"subtract", ^{
    expect(GLKVector3Make(5, 5, 5) - GLKVector3Make(1, 2, 3) ==
           GLKVector3Make(4, 3, 2)).to.beTruthy();
  });

  it(@"scalar multiply", ^{
    expect(GLKVector3Make(1, 2, 3) * 2.f == GLKVector3Make(2, 4, 6)).to.beTruthy();
    expect(2.f * GLKVector3Make(1, 2, 3) == GLKVector3Make(2, 4, 6)).to.beTruthy();
  });

  it(@"element-wise multiply", ^{
    expect(GLKVector3Make(1, 2, 3) * GLKVector3Make(4, 5, 6))
        .to.beCloseToGLKVector(GLKVector3Make(4, 10, 18));
  });
  
  it(@"division", ^{
    expect(GLKVector3Make(2, 4, 6) / 2.f == GLKVector3Make(1, 2, 3)).to.beTruthy();
  });

  it(@"range", ^{
    GLKVector3 vec = GLKVector3Make(1, 2, 3);
    expect(GLKVector3InRange(vec, 1, 3)).to.beTruthy();
    expect(GLKVector3InRange(vec, 1, 2.5)).to.beFalsy();
    expect(GLKVector3InRange(vec, 1.5, 3)).to.beFalsy();
    expect(GLKVector3InRange(vec, 3, 7)).to.beFalsy();
  });

  it(@"sum", ^{
    expect(std::sum(GLKVector3Make(1, 2, 3))).to.equal(6.f);
  });

  it(@"round", ^{
    expect(std::round(GLKVector3Make(1.5, 2.7, 3.2)) == GLKVector3Make(2, 3, 3)).to.beTruthy();
  });
  
  it(@"min", ^{
    expect(std::min(GLKVector3Make(1, 2, 3), GLKVector3Make(1, 0, 7)) ==
           GLKVector3Make(1, 0, 3)).to.beTruthy();
  });
  
  it(@"max", ^{
    expect(std::max(GLKVector3Make(1, 2, 3), GLKVector3Make(1, 0, 7)) ==
           GLKVector3Make(1, 2, 7)).to.beTruthy();
  });
});

context(@"GLKVector4 operations", ^{
  it(@"equal", ^{
    expect(GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(1, 2, 3, 4)).to.beTruthy();
    expect(GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(-1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(1, -2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(1, 2, -3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(1, 2, 3, -4)).to.beFalsy();
  });

  it(@"not equal", ^{
    expect(GLKVector4Make(1, 2, 3, 4) != GLKVector4Make(1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) != GLKVector4Make(-1, 2, 3, 4)).to.beTruthy();
    expect(GLKVector4Make(1, 2, 3, 4) != GLKVector4Make(1, -2, 3, 4)).to.beTruthy();
    expect(GLKVector4Make(1, 2, 3, 4) != GLKVector4Make(1, 2, -3, 4)).to.beTruthy();
    expect(GLKVector4Make(1, 2, 3, 4) != GLKVector4Make(1, 2, 3, -4)).to.beTruthy();
  });

  it(@"greater or equal", ^{
    expect(GLKVector4Make(1, 2, 3, 4) <= GLKVector4Make(1, 2, 3, 4)).to.beTruthy();
    expect(GLKVector4Make(1.1, 2, 3, 4) <= GLKVector4Make(1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2.1, 3, 4) <= GLKVector4Make(1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3.1, 4) <= GLKVector4Make(1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4.1) <= GLKVector4Make(1, 2, 3, 4)).to.beFalsy();
    
    expect(GLKVector4Make(1, 2, 3, 4) >= GLKVector4Make(1, 2, 3, 4)).to.beTruthy();
    expect(GLKVector4Make(1, 2, 3, 4) >= GLKVector4Make(1.1, 2, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) >= GLKVector4Make(1, 2.1, 3, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) >= GLKVector4Make(1, 2, 3.1, 4)).to.beFalsy();
    expect(GLKVector4Make(1, 2, 3, 4) >= GLKVector4Make(1, 2, 3, 4.1)).to.beFalsy();
  });
  
  it(@"uniform", ^{
    expect(GLKVector4Make(1) == GLKVector4Make(1, 1, 1, 1)).to.beTruthy();
    expect(GLKVector4Make(2) == GLKVector4Make(2, 2, 2, 2)).to.beTruthy();
  });
  
  it(@"add", ^{
    expect(GLKVector4Make(1, 2, 3, 4) + GLKVector4Make(5, 6, 7, 8) ==
           GLKVector4Make(6, 8, 10, 12)).to.beTruthy();
  });

  it(@"subtract", ^{
    expect(GLKVector4Make(5, 5, 5, 5) - GLKVector4Make(1, 2, 3, 4) ==
           GLKVector4Make(4, 3, 2, 1)).to.beTruthy();
  });

  it(@"scalar multiply", ^{
    expect(GLKVector4Make(1, 2, 3, 4) * 2.f == GLKVector4Make(2, 4, 6, 8)).to.beTruthy();
    expect(2.f * GLKVector4Make(1, 2, 3, 4) == GLKVector4Make(2, 4, 6, 8)).to.beTruthy();
  });

  it(@"element-wise multiply", ^{
    expect(GLKVector4Make(1, 2, 3, 4) * GLKVector4Make(5, 6, 7, 8))
    .to.beCloseToGLKVector(GLKVector4Make(5, 12, 21, 32));
  });
  
  it(@"division", ^{
    expect(GLKVector4Make(2, 4, 6, 8) / 2.f == GLKVector4Make(1, 2, 3, 4)).to.beTruthy();
  });

  it(@"convert from vec4b", ^{
    expect(GLKVector4FromVec4b(cv::Vec4b(0, 255, 0, 255)))
        .to.beCloseToGLKVector(GLKVector4Make(0, 1, 0, 1));
  });

  it(@"sum", ^{
    expect(std::sum(GLKVector4Make(1, 2, 3, 4))).to.equal(10.f);
  });

  it(@"round", ^{
    expect(std::round(GLKVector4Make(1.5, 2.7, 3.2, 4.0)) ==
           GLKVector4Make(2, 3, 3, 4)).to.beTruthy();
  });

  it(@"min", ^{
    expect(std::min(GLKVector4Make(1, 2, 3, 4), GLKVector4Make(1, 0, 7, -5)) ==
           GLKVector4Make(1, 0, 3, -5)).to.beTruthy();
  });

  it(@"max", ^{
    expect(std::max(GLKVector4Make(1, 2, 3, 4), GLKVector4Make(1, 0, 7, -5)) ==
           GLKVector4Make(1, 2, 7, 4)).to.beTruthy();
  });
});

context(@"standard line equation", ^{
  it(@"should calculate line equations from CGPoints", ^{
    CGPoint p0 = CGPointMake(-2, 0);
    CGPoint p1 = CGPointMake(4, -5);
    expect(GLKLineEquation(CGPointZero, CGPointZero)).to.beCloseToGLKVector(GLKVector3Zero);
    expect(GLKLineEquation(p0, p0)).to.beCloseToGLKVector(GLKVector3Zero);
    expect(GLKLineEquation(p1, p1)).to.beCloseToGLKVector(GLKVector3Zero);
    
    expect(GLKLineEquation(p0, p1)).to.beCloseToGLKVector(-GLKLineEquation(p1, p0));
    expect(GLKLineEquation(CGPointZero, p1)).to.beCloseToGLKVector(-GLKLineEquation(p1,
                                                                                    CGPointZero));
    expect(GLKLineEquation(p0, CGPointZero)).to.beCloseToGLKVector(-GLKLineEquation(CGPointZero,
                                                                                    p0));
    
    GLKVector3 line = GLKLineEquation(p0, p1);
    expect(line).to.beCloseToGLKVector(GLKVector3Make(-0.5, -0.6, -1));
    expect(GLKVector3DotProduct(line, GLKVector3Make(p0.x, p0.y, 1))).to.equal(0);
    expect(GLKVector3DotProduct(line, GLKVector3Make(p1.x, p1.y, 1))).to.equal(0);
    
    line = GLKLineEquation(CGPointZero, p0);
    expect(line).to.beCloseToGLKVector(GLKVector3Make(0, 2, 0));
    expect(GLKVector3DotProduct(line, GLKVector3Make(0, 0, 1))).to.equal(0);
    expect(GLKVector3DotProduct(line, GLKVector3Make(p0.x, p0.y, 1))).to.equal(0);
    
    line = GLKLineEquation(CGPointZero, p1);
    expect(line).to.beCloseToGLKVector(GLKVector3Make(-5, -4, 0));
    expect(GLKVector3DotProduct(line, GLKVector3Make(0, 0, 1))).to.equal(0);
    expect(GLKVector3DotProduct(line, GLKVector3Make(p1.x, p1.y, 1))).to.equal(0);
  });
  
  it(@"should calculate line equations from GLKVector2s", ^{
    CGPoint p0 = CGPointMake(-2, 0);
    CGPoint p1 = CGPointMake(4, -5);
    GLKVector2 v0 = GLKVector2FromCGPoint(p0);
    GLKVector2 v1 = GLKVector2FromCGPoint(p1);
    
    expect(GLKLineEquation(GLKVector2Zero, GLKVector2Zero)).to.beCloseToGLKVector(GLKVector3Zero);
    expect(GLKLineEquation(v0, v0)).to.beCloseToGLKVector(GLKVector3Zero);
    expect(GLKLineEquation(v1, v1)).to.beCloseToGLKVector(GLKVector3Zero);
    
    expect(GLKLineEquation(v0, v1)).to.beCloseToGLKVector(-GLKLineEquation(v1, v0));
    expect(GLKLineEquation(GLKVector2Zero, v1))
        .to.beCloseToGLKVector(-GLKLineEquation(v1, GLKVector2Zero));
    expect(GLKLineEquation(v0, GLKVector2Zero))
        .to.beCloseToGLKVector(-GLKLineEquation(GLKVector2Zero, v0));
    
    expect(GLKLineEquation(v0, v1)).to.beCloseToGLKVector(GLKLineEquation(p0, p1));
    expect(GLKLineEquation(GLKVector2Zero, v0))
        .to.beCloseToGLKVector(GLKLineEquation(CGPointZero, p0));
    expect(GLKLineEquation(GLKVector2Zero, v1))
        .to.beCloseToGLKVector(GLKLineEquation(CGPointZero, p1));
  });
});

context(@"colorspace conversion", ^{
  __block GLKVector4s pixels;
  
  it(@"should convert from rgb to hsv", ^{
    for (float r = 0; r <= 1.0; r += 0.1) {
      for (float g = 0; g <= 1.0; g += 0.1) {
        for (float b = 0; b <= 1.0; b += 0.1) {
          for (float a = 0; a <= 1.0; a += 0.1) {
            pixels.push_back(GLKVector4Make(r, g, b, a));
          }
        }
      }
    }
    
    for (const auto rgba : pixels) {
      GLKVector4 hsva = GLKRGBA2HSVA(rgba);
      CGFloat h,s,v;
      [[UIColor colorWithGLKVector:rgba] getHue:&h saturation:&s brightness:&v alpha:nil];
      expect(hsva).to.beCloseToGLKVectorWithin(GLKVector4Make(h, s, v, rgba.a), 1e-4);
    }
  });
  
  it(@"should convert from rgb to yiq", ^{
    GLKVector3 yiq = GLKRGB2YIQ(GLKVector3Make(1, 1, 1));
    expect(yiq).to.beCloseToGLKVectorWithin(GLKVector3Make(1, 0 , 0), 1e-4);
  });
});

SpecEnd
