// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTGLTexture.h"
#import "LTGLException.h"
#import "LTTestUtils.h"

SpecBegin(LTFbo)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

context(@"init with texture", ^{
  it(@"should init with RGBA byte texture", ^{
    LTTexture *texture = [LTGLTexture alloc] initWithSize:<#(CGSize)#> precision:<#(LTTexturePrecision)#> channels:<#(LTTextureChannels)#> allocateMemory:<#(BOOL)#>
  });
  
  it(@"should init with half-float RGBA texture on capable devies", ^{
    
  });
  
  it(@"should not init with half-float RGBA texture on incapable devies", ^{
    
  });
  
  it(@"should not init with float RGBA texture on incapable devies", ^{
    
  });
  
  it(@"should not init with non-RGBA texture", ^{
    
  });
  
  it(@"should not init with zero-size texture", ^{
    
  });
  
  pending(@"should init with LTCachedTexture");
});

context(@"binding/unbinding", ^{
  it(@"should bind to openGL", ^{
    
  });
  it(@"should unbind to previous", ^{
    
  });
  it(@"should unbind to another fbo", ^{
    
  });
});

SpecEnd