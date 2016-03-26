// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTShaderStorage+ShaderVsh.h"

SpecBegin(LTShaderStorage)

it(@"should load shader contents with static call", ^{
  NSString *shader = [ShaderVsh source];

  expect(shader).to.contain(@"main");
  expect(shader).to.contain(@"vec4");
  expect(shader).to.contain(@"gl_Position");
});

it(@"should contain shader uniforms", ^{
  expect([ShaderVsh value]).to.equal(@"value");
});

it(@"should contain shader attributes", ^{
  expect([ShaderVsh position]).to.equal(@"position");
});

SpecEnd
