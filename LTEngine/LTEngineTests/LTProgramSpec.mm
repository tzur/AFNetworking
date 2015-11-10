// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"

#import "LTGLException.h"
#import "LTGPUResourceExamples.h"

static NSString * const kBasicVertexSource = @"void main() { gl_Position = vec4(0.0); }";
static NSString * const kBasicFragmentSource = @"void main() { gl_FragColor = vec4(0.0); }";

static NSString * const kComplexVertexSource = @"varying highp vec2 myVarying; "
    "uniform highp mat4 myUniform; "
    "attribute highp vec2 myAttr; "
    "void main() { myVarying = myAttr; gl_Position = vec4(myUniform); }";
static NSString * const kComplexFragmentSource = @"varying highp vec2 myVarying; "
    "void main() { gl_FragColor = vec4(myVarying.x, myVarying.y, 0.0, 0.0); }";

static NSString * const kUniformTypesVertexSource =
  @"uniform bool uBool; "
  "uniform highp int uInt; "
  "uniform highp float uFloat; "
  "uniform highp vec2 uVec2; "
  "uniform highp vec3 uVec3; "
  "uniform highp vec4 uVec4; "
  "uniform highp mat2 uMat2; "
  "uniform highp mat3 uMat3; "
  "uniform highp mat4 uMat4; "
  "uniform highp sampler2D uSampler; "
  "void main() { "
  "  uBool; "
  "  uInt; "
  "  uFloat; "
  "  texture2D(uSampler, vec2(0.0)); "
  "  uVec2; "
  "  uVec3; "
  "  uVec4; "
  "  uMat2; "
  "  uMat3; "
  "  uMat4; "
  "  gl_Position = vec4(0.0); "
  "} ";

SpecBegin(LTProgram)

context(@"getting and setting uniforms and attributes", ^{
  __block LTProgram *program;

  __block NSNumber *boolValue;
  __block NSNumber *intValue;
  __block NSNumber *floatValue;
  
  __block NSValue *vec2;
  __block NSValue *vec3;
  __block NSValue *vec4;
  
  __block NSValue *mat2;
  __block NSValue *mat3;
  __block NSValue *mat4;
  
  beforeEach(^{
    program = [[LTProgram alloc] initWithVertexSource:kUniformTypesVertexSource
                                       fragmentSource:kBasicFragmentSource];
    
    boolValue = @(YES);
    intValue = @(7);
    floatValue = @(1.f);
    
    vec2 = $(LTVector2(1.f, 2.f));
    vec3 = $(LTVector3(1.f, 2.f, 3.f));
    vec4 = $(LTVector4(1.f, 2.f, 3.f, 4.f));
    
    GLKMatrix2 m2;
    for (int i = 0; i < 4; ++i) {
      m2.m[i] = (float)i;
    }
    GLKMatrix3 m3;
    for (int i = 0; i < 9; ++i) {
      m3.m[i] = (float)i;
    }
    GLKMatrix4 m4;
    for (int i = 0; i < 16; ++i) {
      m4.m[i] = (float)i;
    }
    
    mat2 = $(m2);
    mat3 = $(m3);
    mat4 = $(m4);
  });
  
  it(@"should set and get uniform values", ^{
    program[@"uBool"] = boolValue;
    program[@"uInt"] = intValue;
    program[@"uFloat"] = floatValue;
    program[@"uSampler"] = intValue;
    program[@"uVec2"] = vec2;
    program[@"uVec3"] = vec3;
    program[@"uVec4"] = vec4;
    program[@"uMat2"] = mat2;
    program[@"uMat3"] = mat3;
    program[@"uMat4"] = mat4;
    program[@"uSampler"] = intValue;

    expect(program[@"uBool"]).to.equal(boolValue);
    expect(program[@"uInt"]).to.equal(intValue);
    expect(program[@"uFloat"]).to.equal(floatValue);
    expect(program[@"uSampler"]).to.equal(intValue);
    expect([program[@"uVec2"] isEqualToValue:vec2]).to.beTruthy();
    expect([program[@"uVec3"] isEqualToValue:vec3]).to.beTruthy();
    expect([program[@"uVec4"] isEqualToValue:vec4]).to.beTruthy();
    expect([program[@"uMat2"] isEqualToValue:mat2]).to.beTruthy();
    expect([program[@"uMat3"] isEqualToValue:mat3]).to.beTruthy();
    expect([program[@"uMat4"] isEqualToValue:mat4]).to.beTruthy();
  });
  
  context(@"uniform type validation", ^{
    it(@"should not set uniform booleans with invalid values", ^{
      expect(^{
        program[@"uBool"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uBool"] = vec2;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform integers with invalid values", ^{
      expect(^{
        program[@"uInt"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = vec2;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should set uniform integers with small, medium sized and large values", ^{
      expect(^{
        program[@"uInt"] = @(INT_MIN);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(12345);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(INT_MAX);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(LONG_MIN);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(123456789);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(LONG_MAX);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(LONG_LONG_MIN);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(1234567890123456789);
      }).toNot.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uInt"] = @(LONG_LONG_MAX);
      }).toNot.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform samplers with invalid values", ^{
      expect(^{
        program[@"uSampler"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uSampler"] = vec2;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform floats with invalid values", ^{
      expect(^{
        program[@"uFloat"] = vec2;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform vector2's with invalid values", ^{
      expect(^{
        program[@"uVec2"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec2"] = vec3;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec2"] = mat3;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform vector3's with invalid values", ^{
      expect(^{
        program[@"uVec3"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec3"] = vec2;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec3"] = mat3;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform vector4's with invalid values", ^{
      expect(^{
        program[@"uVec4"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec4"] = vec3;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uVec4"] = mat3;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform matrix2's with invalid values", ^{
      expect(^{
        program[@"uMat2"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat2"] = vec2;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat2"] = mat3;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform matrix3's with invalid values", ^{
      expect(^{
        program[@"uMat3"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat3"] = vec2;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat3"] = mat2;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not set uniform matrix4's with invalid values", ^{
      expect(^{
        program[@"uMat4"] = floatValue;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat4"] = vec2;
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        program[@"uMat4"] = mat3;
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"compiling shaders", ^{
  it(@"should compile matching uniform", ^{
    NSString *vertexSource = @"uniform highp mat4 myUniform; "
    "void main() { gl_Position = vec4(myUniform); }";
    
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:vertexSource
                                                  fragmentSource:kBasicFragmentSource];
    
    expect(program).toNot.beNil();
  });
  
  it(@"should fail compiling matching varyings", ^{
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:kComplexVertexSource
                                                  fragmentSource:kComplexFragmentSource];
    
    expect(program).toNot.beNil();
  });
  
  it(@"should fail compiling with non matching varyings", ^{
    NSString *vertexSource = @"varying highp vec2 myVarying; "
    "uniform highp mat4 myUniform; "
    "attribute highp vec2 myAttr; "
    "void main() { myVarying = myAttr; gl_Position = vec4(myUniform); }";
    NSString *fragmentSource = @"varying highp vec2 myVaryingFoo; "
    "void main() { gl_FragColor = vec4(myVaryingFoo.x, myVaryingFoo.y, 0.0, 0.0); }";
    
    expect(^{
      __unused LTProgram *program =
          [[LTProgram alloc] initWithVertexSource:vertexSource
                                   fragmentSource:fragmentSource];
    }).to.raise(kLTProgramLinkFailedException);
  });
});

context(@"uniforms and attributes presence", ^{
  __block LTProgram *program = nil;
  
  beforeEach(^{
    program = [[LTProgram alloc] initWithVertexSource:kComplexVertexSource
                                       fragmentSource:kComplexFragmentSource];
  });
  
  it(@"should contain valid attribute", ^{
    expect([program containsAttribute:@"myAttr"]).to.equal(YES);
  });
  
  it(@"should not contain invalid attribute", ^{
    expect([program containsAttribute:@"myAttrFoo"]).to.equal(NO);
  });
  
  it(@"should contain valid uniform", ^{
    expect([program containsUniform:@"myUniform"]).to.equal(YES);
  });
  
  it(@"should not contain invalid uniform", ^{
    expect([program containsUniform:@"myUniformFoo"]).to.equal(NO);
  });

  it(@"should contain exact set of attributes", ^{
    expect(program.attributes).to.equal([NSSet setWithArray:@[@"myAttr"]]);
  });

  it(@"should contain exact set of uniforms", ^{
    expect(program.uniforms).to.equal([NSSet setWithArray:@[@"myUniform"]]);
  });
});

context(@"binding", ^{
  __block LTProgram *program = nil;

  beforeEach(^{
    program = [[LTProgram alloc] initWithVertexSource:kComplexVertexSource
                                       fragmentSource:kComplexFragmentSource];
  });

  afterEach(^{
    program = nil;
  });

  itShouldBehaveLike(kLTResourceExamples, ^{
    NSLog(@"generating dict");
    return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:program],
             kLTResourceExamplesOpenGLParameterName: @GL_CURRENT_PROGRAM};
  });
});

SpecEnd
