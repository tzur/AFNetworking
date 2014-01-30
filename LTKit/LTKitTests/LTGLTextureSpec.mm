// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTTextureExamples.h"

SpecBegin(LTGLTexture)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

itShouldBehaveLike(kLTTextureExamples, @{kLTTextureExamplesTextureClass: [LTGLTexture class]});

SpecEnd
