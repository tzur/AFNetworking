// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSScanner+LTEngine.h"

#import "LTGLKitExtensions.h"

SpecBegin(NSScanner_LTEngineSpec)

__block NSScanner *scanner;

context(@"float values", ^{
  __block float actual;

  it(@"should scan float value correctly", ^{
    const std::vector<std::pair<float, const char *>> values = {
        {0, "0"},
        {-1, "-1.0"},
        {-1, "-1"},
        {-1, "-1.0000"},
        {NAN, "nan"},
        {INFINITY, "inf"},
        {-INFINITY, "-inf"},
        {-1.3e7, "-1.3e7"},
        {1.123, "1.123"},
        {15, "15"}
    };

    for (auto value : values) {
      scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:value.second]];
      auto expected = value.first;

      expect([scanner lt_scanFloat:&actual]).to.beTruthy();
      expect(expected).to.equal(actual);
    }
  });

  it(@"should fail to scan non float value", ^{
    scanner = [NSScanner scannerWithString:@"foo"];
    expect([scanner lt_scanFloat:&actual]).to.beFalsy();
  });
});

context(@"comma separated floats", ^{
  it(@"should scan valid inputs successfully", ^{
    __block float value;
    float expectedValue = 3.14;
    scanner = [NSScanner scannerWithString:@"3.14"];
    expect([scanner lt_scanCommaSeparatedFloats:&value length:1]).to.beTruthy();
    expect(value).to.equal(expectedValue);

    __block GLKVector2 vec2;
    auto expectedVec2 = GLKVector2Make(1.f, 2.f);
    scanner = [NSScanner scannerWithString:@"1, 2"];
    expect([scanner lt_scanCommaSeparatedFloats:vec2.v length:2]).to.beTruthy();
    expect(vec2 == expectedVec2).to.beTruthy();

    __block GLKVector4 vec4;
    auto expectedVec4 = GLKVector4Make(1.f, NAN, INFINITY, -1.23e4f);
    scanner = [NSScanner scannerWithString:@"1, nan, inf, -1.23e4"];
    expect([scanner lt_scanCommaSeparatedFloats:vec4.v length:4]).to.beTruthy();
    expect(vec4 == expectedVec4).to.beTruthy();
  });

  it(@"should not scan illegal inputs", ^{
    __block GLKVector2 vec2;
    scanner = [NSScanner scannerWithString:@"1.1 nan"];
    expect([scanner lt_scanCommaSeparatedFloats:vec2.v length:sizeof(vec2.v)]).to.beFalsy();

    __block GLKVector4 vec4;
    scanner = [NSScanner scannerWithString:@"1, 2, 3 4"];
    expect([scanner lt_scanCommaSeparatedFloats:vec4.v length:sizeof(vec4.v)]).to.beFalsy();
  });
});

context(@"vector", ^{
  it(@"should scan valid inputs successfully", ^{
    __block float value;
    float expectedValue = 15;
    scanner = [NSScanner scannerWithString:@"{15}"];
    expect([scanner lt_scanFloatVector:&value length:1]).to.beTruthy();
    expect(value).to.equal(expectedValue);

    __block GLKVector2 vec2;
    auto expectedVec2 = GLKVector2Make(1.1, 2);
    scanner = [NSScanner scannerWithString:@"{1.1, 2}"];
    expect([scanner lt_scanFloatVector:vec2.v length:2]).to.beTruthy();
    expect(vec2 == expectedVec2).to.beTruthy();

    __block GLKVector4 vec4;
    auto expectedVec4 = GLKVector4Make(1.1, NAN, INFINITY, -1.23e4f);
    scanner = [NSScanner scannerWithString:@"{1.1, nan, inf, -1.23e4}"];
    expect([scanner lt_scanFloatVector:vec4.v length:4]).to.beTruthy();
    expect(vec4 == expectedVec4).to.beTruthy();
  });

  it(@"should not scan illegal inputs", ^{
    __block GLKVector2 vec2;
    scanner = [NSScanner scannerWithString:@"{-inf nan}"];
    expect([scanner lt_scanFloatVector:vec2.v length:2]).to.beFalsy();

    __block GLKVector4 vec4;
    scanner = [NSScanner scannerWithString:@"{1, 2, 3 4}"];
    expect([scanner lt_scanFloatVector:vec4.v length:4]).to.beFalsy();
  });
});

context(@"matrix", ^{
  it(@"should scan valid inputs successfully", ^{
    __block float value;
    float expectedValue = 1500.75;
    scanner = [NSScanner scannerWithString:@"{{1500.75}}"];
    expect([scanner lt_scanFloatMatrix:&value rows:1 cols:1]).to.beTruthy();
    expect(value).to.equal(expectedValue);

    __block GLKMatrix2 mat2;
    GLKMatrix2 expectedMat2 = {{1, 2, 3, 4}};
    scanner = [NSScanner scannerWithString:@"{{1, 2}, {3, 4}}"];
    expect([scanner lt_scanFloatMatrix:mat2.m rows:2 cols:2]).to.beTruthy();
    expect(mat2 == expectedMat2).to.beTruthy();

    __block GLKMatrix4 mat4;
    auto expectedMat4 = GLKMatrix4Make(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    scanner = [NSScanner scannerWithString:@"{{1,2,3,4},{5,6,7,8},{9,10,11,12},{13,14,15,16}}"];
    expect([scanner lt_scanFloatMatrix:mat4.m rows:4 cols:4]).to.beTruthy();
    expect(mat4 == expectedMat4).to.beTruthy();
  });

  it(@"should not scan illegal inputs", ^{
    __block GLKMatrix2 mat2;
    scanner = [NSScanner scannerWithString:@"{(-inf, nan), (3, 4)}"];
    expect([scanner lt_scanFloatMatrix:mat2.m rows:2 cols:2]).to.beFalsy();

    __block GLKMatrix4 vec4;
    scanner = [NSScanner scannerWithString:@"{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}"];
    expect([scanner lt_scanFloatMatrix:vec4.m rows:4 cols:4]).to.beFalsy();
  });
});

context(@"NSUInteger values", ^{
  __block NSUInteger actual;

  it(@"should scan NSUInteger value correctly", ^{
    NSDecimalNumber *maxNumber = [NSDecimalNumber decimalNumberWithMantissa:NSUIntegerMax exponent:0
                                                                 isNegative:NO];
    const std::vector<std::pair<NSUInteger, const char *>> values = {
      {0, "0"},
      {1, "1"},
      {7, "7"},
      {NSUIntegerMax - 1,
       [[[maxNumber decimalNumberBySubtracting:NSDecimalNumber.one] stringValue] UTF8String]},
      {NSUIntegerMax, [[maxNumber stringValue] UTF8String]},
      {NSUIntegerMax,
       [[[maxNumber decimalNumberByAdding:NSDecimalNumber.one] stringValue] UTF8String]}
    };

    for (auto value : values) {
      scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:value.second]];
      auto expected = value.first;

      expect([scanner lt_scanNSUInteger:&actual]).to.beTruthy();
      expect(expected).to.equal(actual);
    }
  });

  it(@"should fail to scan negative value", ^{
    scanner = [NSScanner scannerWithString:@"-1"];
    expect([scanner lt_scanNSUInteger:&actual]).to.beFalsy();
  });

  it(@"should fail to scan non-NSUInteger value", ^{
    scanner = [NSScanner scannerWithString:@"foo"];
    expect([scanner lt_scanNSUInteger:&actual]).to.beFalsy();
  });

  it(@"should leave value of given reference unchanged when failing to scan value", ^{
    actual = 7;
    scanner = [NSScanner scannerWithString:@"foo"];
    [scanner lt_scanNSUInteger:&actual];
    expect(actual).to.equal(7);
  });
});

SpecEnd
