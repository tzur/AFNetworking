// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTFbo.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+ColorizeFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTextureExamples.h"

@interface LTMMTexture ()
@property (nonatomic) BOOL needsSynchronizationBeforeHostAccess;
@end

SpecBegin(LTMMTexture)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

itShouldBehaveLike(kLTTextureExamples, @{kLTTextureExamplesTextureClass: [LTMMTexture class]});

it(@"should read correct data after gpu draw", ^{
  LTMMTexture *target = [[LTMMTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                precision:LTTexturePrecisionByte
                                                 channels:LTTextureChannelsRGBA
                                           allocateMemory:YES];
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage passthroughVsh]
                                                fragmentSource:[LTShaderStorage colorizeFsh]];
  LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:target];
  drawer[@"color"] = [NSValue valueWithGLKVector4:GLKVector4Make(1.0, 0.0, 0.0, 1.0)];

  CGRect rect = CGRectMake(0, 0, target.size.width, target.size.height);
  [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

  expect(target.needsSynchronizationBeforeHostAccess).to.beTruthy();

  [target updateTexture:^(cv::Mat texture) {
    expect(target.needsSynchronizationBeforeHostAccess).to.beFalsy();
    expect(LTCompareMatWithValue(cv::Scalar(255, 0, 0, 255), texture)).to.beTruthy();
  }];
});

SpecEnd
