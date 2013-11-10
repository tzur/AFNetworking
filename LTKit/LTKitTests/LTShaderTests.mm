// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#define EXP_SHORTHAND
#define MOCKITO_SHORTHAND

#import "LTShader.h"

#import <OCMockitoIOS/OCMockitoIOS.h>
#import <XCTest/XCTest.h>

#import "Expecta.h"
#import "LTGLException.h"

static NSString * const kBasicVertexSource = @"void main() { gl_Position = vec4(0.0); }";
static NSString * const kBasicFragmentSource = @"void main() { gl_FragColor = vec4(0.0); }";
static NSString * const kInvalidVertexSource = @"foo;";
static NSString * const kInvalidFragmentSource = @"foo;";

@interface LTShaderTests : XCTestCase
@end

@implementation LTShaderTests

- (void)setUp {
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
}

- (void)tearDown {
  [EAGLContext setCurrentContext:nil];
}

- (void)testVertexShaderShouldCompileWithEmptySource {
  LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeVertex andSource:@""];
  
  expect(shader).notTo.beNil();
}

- (void)testFragmentShaderShouldCompileWithEmptySource {
  LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeFragment andSource:@""];

  expect(shader).notTo.beNil();
}

- (void)testVertexShaderShouldFailCompilingInvalidSource {
  expect(^{
    __unused LTShader *share = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                                    andSource:kInvalidVertexSource];
  }).to.raise(kLTShaderCompilationFailedException);
}

- (void)testFragmentShaderShouldFailCompilingInvalidSource {
  expect(^{
    __unused LTShader *share = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                                    andSource:kInvalidFragmentSource];
  }).to.raise(kLTShaderCompilationFailedException);
}

- (void)testShaderShouldCompileBasicVertexShader {
  LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                          andSource:kBasicVertexSource];
  
  expect(shader).notTo.beNil();
}

- (void)testShaderShouldCompileBasicFragmentShader {
  LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                          andSource:kBasicFragmentSource];
  
  expect(shader).notTo.beNil();
}

@end
