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
  return [self loadComplexProgramWithUniforms:@[@"myUniform"] attributes:@[@"myAttr"]];
}

- (LTProgram *)loadComplexProgramWithUniforms:(NSArray *)uniforms attributes:(NSArray *)attributes {
  return [[LTProgram alloc] initWithVertexSource:kComplexVertexSource
                                  fragmentSource:kComplexFragmentSource uniforms:uniforms
                                   andAttributes:attributes];
}

- (void)testProgramShouldFailCompilingWithInvalidUniformName {
  expect(^{
    __unused LTProgram *program =
        [[LTProgram alloc] initWithVertexSource:kBasicVertexSource
                                 fragmentSource:kBasicFragmentSource
                                       uniforms:@[@"myUniform"] andAttributes:nil];
  }).to.raise(kLTProgramUniformNotFoundException);
}

- (void)testProgramShouldSucceedCompilingWithMatchingUniform {
  NSString *vertexSource = @"uniform highp mat4 myUniform; "
      "void main() { gl_Position = vec4(myUniform); }";
  
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:vertexSource
                                                fragmentSource:kBasicFragmentSource
                                                      uniforms:@[@"myUniform"] andAttributes:nil];
  
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
                                 fragmentSource:fragmentSource
                                       uniforms:@[@"myUniform"]
                                  andAttributes:@[@"myAttr"]];
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

@end
