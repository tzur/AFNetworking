// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Metal/Metal.h>

#import "LTGLContext.h"
#import "LTGLException.h"
#import "LTGLTexture.h"
#import "LTGPUResourceExamples.h"
#import "LTTexture+Factory.h"
#import "LTTextureBasicExamples.h"

// LTTexture spec is tested by the concrete class LTGLTexture.

// TODO: (yaron) refactor LTTexture to test the abstract functionality in a different spec. This
// is probably possible only by refactoring the LTTexture abstract class to the strategy pattern:
// http://stackoverflow.com/questions/243274/best-practice-with-unit-testing-abstract-classes

SpecBegin(LTTexture)

context(@"properties", ^{
  it(@"will not set wrap to repeat on NPOT texture", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 3)];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).toNot.equal(LTTextureWrapRepeat);
  });

  it(@"will set the warp to repeat on POT texture", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).to.equal(LTTextureWrapRepeat);
  });

  it(@"will set min and mag filters", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationNearest);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationNearest);
  });
});

context(@"binding and execution", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"binding", ^{
    itShouldBehaveLike(kLTResourceExamples, ^{
      return @{
        kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:texture],
        kLTResourceExamplesOpenGLParameterName: @GL_TEXTURE_BINDING_2D,
        kLTResourceExamplesIsResourceFunction:
            [NSValue valueWithPointer:(const void *)glIsTexture]
      };
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

    itShouldBehaveLike(kLTTextureDefaultValuesExamples, ^{
      [texture executeAndPreserveParameters:^{
        texture.minFilterInterpolation = LTTextureInterpolationNearest;
        texture.magFilterInterpolation = LTTextureInterpolationNearest;
        texture.wrap = LTTextureWrapRepeat;
      }];
      return @{kLTTextureDefaultValuesTexture:
                 [NSValue valueWithNonretainedObject:texture]};
    });
  });
});

dcontext(@"metal texture from opengl texture", ^{
  __block id<MTLDevice> device;
  __block CGSize size;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
    size = CGSizeMake(39, 47);
  });

  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    if ((pixelFormat.dataType == LTGLPixelDataType32Float &&
         ![LTGLContext currentContext].canRenderToFloatColorBuffers) ||
        pixelFormat.value == LTGLPixelFormatDepth16Unorm) {
      // Pixel format isn't supported, return.
      return;
    }

    it(@"should return non mipmap texture", ^{
      auto image = cv::Mat(size.height, size.width, pixelFormat.matType);
      auto ltTexture = [[LTGLTexture alloc] initWithImage:image];
      auto mtlTexture = [ltTexture mtlTextureWithDevice:device];
      expect(mtlTexture.width).to.equal(ltTexture.size.width);
      expect(mtlTexture.height).to.equal(ltTexture.size.height);
      expect(mtlTexture.pixelFormat).to.equal(ltTexture.pixelFormat.mtlPixelFormat);
      expect(mtlTexture.mipmapLevelCount).to.equal(1);
    });

    it(@"should return mipmap texture", ^{
      auto image = cv::Mat(size.height, size.width, pixelFormat.matType);
      auto image1 = cv::Mat(size.height / 2, size.width / 2, pixelFormat.matType);
      auto ltTexture = [[LTGLTexture alloc] initWithMipmapImages:{image, image1}];
      auto mtlTexture = [ltTexture mtlTextureWithDevice:device];
      expect(mtlTexture.width).to.equal(ltTexture.size.width);
      expect(mtlTexture.height).to.equal(ltTexture.size.height);
      expect(mtlTexture.pixelFormat).to.equal(ltTexture.pixelFormat.mtlPixelFormat);
      expect(mtlTexture.mipmapLevelCount).to.equal(2);
    });
  }];
});

SpecEnd
