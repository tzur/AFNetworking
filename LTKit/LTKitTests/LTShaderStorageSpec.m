// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTShaderStorage+ShaderVsh.h"

SpecBegin(LTShaderStorage)

it(@"should load shader contents with static call", ^{
  NSString *shader = [LTShaderStorage shaderVsh];

  expect(shader).to.contain(@"main");
  expect(shader).to.contain(@"vec4");
  expect(shader).to.contain(@"gl_Position");
});

it(@"should load shader contents with dynamic lookup", ^{
  NSString *staticShader = [LTShaderStorage shaderVsh];
  NSString *dynamicShader = [LTShaderStorage shaderSourceWithName:@"shaderVsh"];

  expect(dynamicShader).to.equal(staticShader);
});

SpecEnd
