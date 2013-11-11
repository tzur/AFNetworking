// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTShader.h"

#import "LTGLException.h"

static NSString * const kBasicVertexSource = @"void main() { gl_Position = vec4(0.0); }";
static NSString * const kBasicFragmentSource = @"void main() { gl_FragColor = vec4(0.0); }";
static NSString * const kInvalidVertexSource = @"foo;";
static NSString * const kInvalidFragmentSource = @"foo;";

SpecBegin(LTShader)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

context(@"shader compilation", ^{
  it(@"should compile vertex shader with an empty source", ^{
    LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeVertex andSource:@""];
    
    expect(shader).notTo.beNil();
  });
  
  it(@"should compile fragment shader with an empty source", ^{
    LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeFragment andSource:@""];
    
    expect(shader).notTo.beNil();
  });
  
  it(@"should fail compiling invalid vertex shader source", ^{
    expect(^{
      __unused LTShader *share = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                                      andSource:kInvalidVertexSource];
    }).to.raise(kLTShaderCompilationFailedException);
  });
  
  it(@"should fail compiling invalid fragment shader source", ^{
    expect(^{
      __unused LTShader *share = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                                      andSource:kInvalidFragmentSource];
    }).to.raise(kLTShaderCompilationFailedException);
  });
  
  it(@"should compile basic vertex shader", ^{
    LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                            andSource:kBasicVertexSource];
    
    expect(shader).notTo.beNil();
  });
  
  it(@"should compile basic fragment shader", ^{
    LTShader *shader = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                            andSource:kBasicFragmentSource];
    
    expect(shader).notTo.beNil();
  });
});

SpecEnd
