// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#define EXP_SHORTHAND
#define MOCKITO_SHORTHAND

#import "LTProgram.h"

#import <OCMockitoIOS/OCMockitoIOS.h>
#import <XCTest/XCTest.h>

#import "Expecta.h"
#import "LTGLException.h"

static NSString * const kBasicVertexSource = @"void main() { gl_Position = vec4(0.0); }";
static NSString * const kBasicFragmentSource = @"void main() { gl_FragColor = vec4(0.0); }";

static NSString * const kComplexVertexSource = @"varying highp vec2 myVarying; "
    "uniform highp mat4 myUniform; "
    "attribute highp vec2 myAttr; "
    "void main() { myVarying = myAttr; gl_Position = vec4(myUniform); }";
static NSString * const kComplexFragmentSource = @"varying highp vec2 myVarying; "
    "void main() { gl_FragColor = vec4(myVarying.x, myVarying.y, 0.0, 0.0); }";

static NSString * const kUniformTypesVertexSource =
  @"uniform highp int uInt; "
  "uniform highp float uFloat; "
  "uniform highp vec2 uVec2; "
  "uniform highp vec3 uVec3; "
  "uniform highp vec4 uVec4; "
  "uniform highp mat2 uMat2; "
  "uniform highp mat3 uMat3; "
  "uniform highp mat4 uMat4; "
  "void main() { "
  "  uInt; "
  "  uFloat; "
  "  uVec2; "
  "  uVec3; "
  "  uVec4; "
  "  uMat2; "
  "  uMat3; "
  "  uMat4; "
  "  gl_Position = vec4(0.0); "
  "} ";

@interface LTProgramTests : XCTestCase
@end

@implementation LTProgramTests

- (void)setUp {
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
}

- (void)tearDown {
  [EAGLContext setCurrentContext:nil];
}

- (LTProgram *)loadComplexProgram {
  return [[LTProgram alloc] initWithVertexSource:kComplexVertexSource
                                  fragmentSource:kComplexFragmentSource];
}

- (void)testProgramShouldSucceedCompilingWithMatchingUniform {
  NSString *vertexSource = @"uniform highp mat4 myUniform; "
      "void main() { gl_Position = vec4(myUniform); }";
  
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:vertexSource
                                                fragmentSource:kBasicFragmentSource];
  
  expect(program).toNot.beNil();
}

- (void)testProgramShouldSucceedCompilingWithMatchingVaryings {
  LTProgram *program = [self loadComplexProgram];
  
  expect(program).toNot.beNil();
}

- (void)testProgramShouldFailCompilingWithNonMatchingVaryings {
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
}

- (void)testValidAttributeNameShouldMatchInitialArrayIndex {
  LTProgram *program = [self loadComplexProgram];

  expect([program containsAttribute:@"myAttr"]).to.equal(YES);
  expect([program attributeForName:@"myAttr"]).to.equal(0U);
}

- (void)testInvalidAttributeNameShouldNotBePresent {
  LTProgram *program = [self loadComplexProgram];

  expect([program containsAttribute:@"myAttrFoo"]).to.equal(NO);
}

- (void)testValidUniformNameShouldReturnValidValue {
  LTProgram *program = [self loadComplexProgram];

  expect([program containsUniform:@"myUniform"]).to.equal(YES);
}

- (void)testInvalidUniformNameShouldNotBePresent {
  LTProgram *program = [self loadComplexProgram];

  expect([program containsUniform:@"myUniformFoo"]).to.equal(NO);
}

- (void)testProgramBindsToOpenGL {
  LTProgram *program = [self loadComplexProgram];
  [program bind];
  
  GLint currentProgram;
  glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
  
  expect(currentProgram).toNot.equal(0);
}

- (void)testProgramUnbindsFromOpenGL {
  LTProgram *program = [self loadComplexProgram];

  [program bind];
  [program unbind];
  
  GLint currentProgram;
  glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);

  expect(currentProgram).to.equal(0);
}

- (void)testProgramSetsUniformValues {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:kUniformTypesVertexSource
                                                fragmentSource:kBasicFragmentSource];
  
  NSNumber *intValue = @(7);
  NSNumber *floatValue = @(1);
  
  NSValue *vec2 = [NSValue valueWithGLKVector2:GLKVector2Make(1.f, 2.f)];
  NSValue *vec3 = [NSValue valueWithGLKVector3:GLKVector3Make(1.f, 2.f, 3.f)];
  NSValue *vec4 = [NSValue valueWithGLKVector4:GLKVector4Make(1.f, 2.f, 3.f, 4.f)];

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
  
  NSValue *mat2 = [NSValue valueWithGLKMatrix2:m2];
  NSValue *mat3 = [NSValue valueWithGLKMatrix3:m3];
  NSValue *mat4 = [NSValue valueWithGLKMatrix4:m4];
  
  program[@"uInt"] = intValue;
  program[@"uFloat"] = floatValue;
  program[@"uVec2"] = vec2;
  program[@"uVec3"] = vec3;
  program[@"uVec4"] = vec4;
  program[@"uMat2"] = mat2;
  program[@"uMat3"] = mat3;
  program[@"uMat4"] = mat4;
  
  expect(program[@"uInt"]).to.equal(intValue);
  expect(program[@"uFloat"]).to.equal(floatValue);
  expect([program[@"uVec2"] isEqualToValue:vec2]).to.beTruthy();
  expect([program[@"uVec3"] isEqualToValue:vec3]).to.beTruthy();
  expect([program[@"uVec4"] isEqualToValue:vec4]).to.beTruthy();
  expect([program[@"uMat2"] isEqualToValue:mat2]).to.beTruthy();
  expect([program[@"uMat3"] isEqualToValue:mat3]).to.beTruthy();
  expect([program[@"uMat4"] isEqualToValue:mat4]).to.beTruthy();
}

@end
