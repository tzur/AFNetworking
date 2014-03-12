// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTTestUtils.h"
#import "LTTextureExamples.h"

// LTTexture spec is tested by the concrete class LTGLTexture.

// TODO: (yaron) refactor LTTexture to test the abstract functionality in a different spec. This
// is probably possible only by refactoring the LTTexture abstract class to the strategy pattern:
// http://stackoverflow.com/questions/243274/best-practice-with-unit-testing-abstract-classes

SpecBegin(LTTexture)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"properties", ^{
  it(@"will not set wrap to repeat on NPOT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 3)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).toNot.equal(LTTextureWrapRepeat);
  });

  it(@"will set the warp to repeat on POT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).to.equal(LTTextureWrapRepeat);
  });

  it(@"will set min and mag filters", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationNearest);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationNearest);
  });

  it(@"will set maximal mipmap level", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:NO];
    texture.maxMipmapLevel = 1000;

    expect(texture.maxMipmapLevel).to.equal(1000);
  });
});

context(@"binding and execution", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1) precision:LTTexturePrecisionByte
                                         format:LTTextureFormatRGBA allocateMemory:NO];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"binding", ^{
    itShouldBehaveLike(kLTResourceExamples, ^{
      return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:texture],
               kLTResourceExamplesOpenGLParameterName: @GL_TEXTURE_BINDING_2D};
    });
    
    it(@"should bind and unbind from the same texture unit", ^{
      glActiveTexture(GL_TEXTURE0);
      [texture bind];
      glActiveTexture(GL_TEXTURE1);
      [texture unbind];
      
      glActiveTexture(GL_TEXTURE0);
      GLint currentTexture;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
    });
    
    it(@"should bind and execute block", ^{
      __block GLint currentTexture;
      __block BOOL didExecute = NO;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
      [texture bindAndExecute:^{
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
        expect(currentTexture).toNot.equal(0);
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });

    it(@"should bind to two texture units at the same time", ^{
      glActiveTexture(GL_TEXTURE0);
      [texture bind];
      glActiveTexture(GL_TEXTURE1);
      [texture bind];

      GLint currentTexture;

      glActiveTexture(GL_TEXTURE0);
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(texture.name);

      glActiveTexture(GL_TEXTURE1);
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(texture.name);
    });
  });
  
  context(@"execution", ^{
    it(@"should execute a block", ^{
      __block BOOL didExecute = NO;
      [texture executeAndPreserveParameters:^{
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });
    
    it(@"should raise exception when trying to execute a nil block", ^{
      expect(^{
        [texture executeAndPreserveParameters:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    itShouldBehaveLike(kLTTextureDefaultValuesExamples, ^{
      [texture executeAndPreserveParameters:^{
        texture.minFilterInterpolation = LTTextureInterpolationNearest;
        texture.magFilterInterpolation = LTTextureInterpolationNearest;
        texture.wrap = LTTextureWrapRepeat;
      }];
      return @{kLTTextureDefaultValuesExamplesTexture:
                 [NSValue valueWithNonretainedObject:texture]};
    });
  });
});

SpecEnd
