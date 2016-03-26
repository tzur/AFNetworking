// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "LTFboPool.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTRenderbuffer.h"
#import "LTTexture+Factory.h"

SpecBegin(LTFboPool)

it(@"should initialize correctly", ^{
  expect(^{
    LTFboPool __unused *fboPool = [[LTFboPool alloc] init];
  }).toNot.raiseAny();
});

context(@"fbo creation", ^{
  __block LTFboPool *fboPool;

  beforeEach(^{
    fboPool = [[LTFboPool alloc] init];
  });

  afterEach(^{
    fboPool = nil;
  });

  context(@"textures", ^{
    __block LTTexture *texture;
    __block LTTexture *anotherTexture;

    beforeEach(^{
      texture = [LTTexture textureWithImage:cv::Mat4b(1, 1)];
      anotherTexture = [LTTexture textureWithImage:cv::Mat4b(1, 1)];
    });

    afterEach(^{
      texture = nil;
      anotherTexture = nil;
    });

    it(@"should return new fbo for new texture", ^{
      LTFbo *fbo = [fboPool fboWithTexture:texture];
      expect(fbo).toNot.beNil();
    });

    it(@"should reuse existing fbo for existing texture", ^{
      LTFbo *fbo = [fboPool fboWithTexture:texture];
      LTFbo *fbo2 = [fboPool fboWithTexture:texture];
      expect(fbo2.name).to.equal(fbo.name);
    });

    it(@"should return different fbos for different textures", ^{
      LTFbo *fbo = [fboPool fboWithTexture:texture];
      LTFbo *fbo2 = [fboPool fboWithTexture:anotherTexture];
      expect(fbo2.name).toNot.equal(fbo.name);
    });

    it(@"should let fbo to be deallocated when no longer held strongly", ^{
      __weak LTFbo *fboToBeDeallocated;

      @autoreleasepool {
        LTFbo *fbo = [fboPool fboWithTexture:texture];
        expect(fbo).toNot.beNil();
        fboToBeDeallocated = fbo;
      }

      expect(fboToBeDeallocated).to.beNil();
    });

    it(@"should not clear texture when creating new fbo", ^{
      const cv::Mat4b image = cv::Mat4b(1, 1, cv::Vec4b(10, 20, 30, 40));
      [texture load:image];

      LTFbo __unused *fbo = [fboPool fboWithTexture:texture];
      expect($([texture image])).to.equalMat($(image));
    });

    it(@"should not clear texture when reusing existing fbo", ^{
      LTFbo *fbo = [fboPool fboWithTexture:texture];

      const cv::Mat4b image = cv::Mat4b(1, 1, cv::Vec4b(10, 20, 30, 40));
      [texture load:image];

      LTFbo *fbo2 = [fboPool fboWithTexture:texture];
      expect(fbo2.name).to.equal(fbo.name);

      expect($([texture image])).to.equalMat($(image));
    });
  });

  context(@"mipmaps", ^{
    __block LTTexture *mipmapTexture;

    beforeEach(^{
      mipmapTexture = [LTTexture textureWithMipmapImages:{
        cv::Mat4b(4, 4), cv::Mat4b(2, 2), cv::Mat4b(1, 1)
      }];
    });

    afterEach(^{
      mipmapTexture = nil;
    });

    it(@"should return different fbos for different mipmap levels", ^{
      LTFbo *fbo = [fboPool fboWithTexture:mipmapTexture level:0];
      LTFbo *fbo2 = [fboPool fboWithTexture:mipmapTexture level:1];
      expect(fbo2.name).toNot.equal(fbo.name);
    });

    it(@"should reuse existing fbo for existing mipmap level", ^{
      LTFbo *fbo = [fboPool fboWithTexture:mipmapTexture level:0];
      LTFbo *fbo2 = [fboPool fboWithTexture:mipmapTexture level:0];
      expect(fbo2.name).to.equal(fbo.name);

      LTFbo *anotherLevelFbo = [fboPool fboWithTexture:mipmapTexture level:1];
      LTFbo *anotherLevelFbo2 = [fboPool fboWithTexture:mipmapTexture level:1];
      expect(anotherLevelFbo2.name).to.equal(anotherLevelFbo.name);
    });
  });

  context(@"renderbuffers", ^{
    __block LTRenderbuffer *renderbuffer;
    __block LTRenderbuffer *anotherRenderbuffer;
    __block CAEAGLLayer *drawable;
    __block CAEAGLLayer *anotherDrawable;

    beforeEach(^{
      drawable = [CAEAGLLayer layer];
      drawable.frame = CGRectMake(0, 0, 1, 1);
      anotherDrawable = [CAEAGLLayer layer];
      anotherDrawable.frame = drawable.frame;

      renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:drawable];
      anotherRenderbuffer = [[LTRenderbuffer alloc] initWithDrawable:anotherDrawable];
    });

    afterEach(^{
      drawable = nil;
      anotherDrawable = nil;

      renderbuffer = nil;
      anotherRenderbuffer = nil;
    });

    it(@"should return new fbo for new renderbuffer", ^{
      LTFbo *fbo = [fboPool fboWithRenderbuffer:renderbuffer];
      expect(fbo).toNot.beNil();
    });

    it(@"should reuse existing fbo for existing renderbuffer", ^{
      LTFbo *fbo = [fboPool fboWithRenderbuffer:renderbuffer];
      LTFbo *fbo2 = [fboPool fboWithRenderbuffer:renderbuffer];
      expect(fbo2.name).to.equal(fbo.name);
    });

    it(@"should return different fbos for different renderbuffers", ^{
      LTFbo *fbo = [fboPool fboWithRenderbuffer:renderbuffer];
      LTFbo *fbo2 = [fboPool fboWithRenderbuffer:anotherRenderbuffer];
      expect(fbo2.name).toNot.equal(fbo.name);
    });

    it(@"should let fbo to be deallocated when no longer held strongly", ^{
      __weak LTFbo *fboToBeDeallocated;

      @autoreleasepool {
        LTFbo *fbo = [fboPool fboWithRenderbuffer:renderbuffer];
        expect(fbo).toNot.beNil();
        fboToBeDeallocated = fbo;
      }

      expect(fboToBeDeallocated).to.beNil();
    });
  });
});

it(@"should have valid current pool", ^{
  expect([LTFboPool currentPool]).toNot.beNil();
});

context(@"current pool from current context", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });

  afterEach(^{
    context = nil;
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should return current pool from current context", ^{
    expect([LTFboPool currentPool]).to.equal(context.fboPool);
  });

  it(@"should not have current pool without current context", ^{
    [LTGLContext setCurrentContext:nil];
    expect([LTFboPool currentPool]).to.beNil();
  });
});

SpecEnd
