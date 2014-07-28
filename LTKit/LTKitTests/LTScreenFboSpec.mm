// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTScreenFbo.h"

#import "LTGPUResourceExamples.h"
#import "LTGLContext.h"
#import "LTGLException.h"
#import "LTGLTexture.h"
#import "LTTextureFbo.h"

SpecGLBegin(LTScreenFbo)

__block GLuint framebuffer;
__block GLuint renderbuffer;

const CGSize kSize = CGSizeMake(16, 16);

beforeEach(^{
  framebuffer = 0;
  renderbuffer = 0;
  
  glGenRenderbuffers(1, &renderbuffer);
  LTGLCheck(@"Failed to generate renderbuffer");
  glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, kSize.width, kSize.height);
  glBindRenderbuffer(GL_RENDERBUFFER, 0);
  LTGLCheck(@"Failed to create renderbuffer storage");
  
  glGenFramebuffers(1, &framebuffer);
  LTGLCheck(@"Failed to generate framebuffer");
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
  LTGLCheck(@"Failed attaching renderbuffer to framebuffer");
  
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (status != GL_FRAMEBUFFER_COMPLETE) {
    [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
     "(status: 0x%x, framebuffer: %d texture: %d)", status, framebuffer, renderbuffer];
  }
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glViewport(0, 0, kSize.width, kSize.height);
});

afterEach(^{
  glDeleteRenderbuffers(1, &renderbuffer);
  LTGLCheck(@"Failed to delete renderbuffer");
  glDeleteRenderbuffers(1, &framebuffer);
  LTGLCheck(@"Failed to delete framebuffer");
  
});

context(@"initialization", ^{
  it(@"should initialize with a valid framebuffer and size", ^{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    LTScreenFbo *fbo = [[LTScreenFbo alloc] initWithSize:CGSizeMake(4, 4)];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    expect(fbo.name).to.equal(framebuffer);
  });
  
  it(@"should raise with an invalid framebuffer", ^{
    
  });
});

context(@"clearing", ^{
  it(@"should clear framebuffer with color", ^{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    LTScreenFbo *fbo = [[LTScreenFbo alloc] initWithSize:kSize];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    [fbo clearWithColor:GLKVector4Make(0, 1, 0, 1)];
    
    cv::Mat4b output(kSize.height, kSize.width, cv::Vec4b(0, 0, 0, 0));
    LTGLContext *context = [LTGLContext currentContext];
    [context executeAndPreserveState:^{
      // Since the default pack alignment is 4, it is necessarry to verify there's no special
      // packing of the texture that may effect the representation of the Mat if the number of bytes
      // per row % 4 != 0.
      context.packAlignment = 1;
      // Read pixels into the mutable data, according to the texture precision.
      glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
      glReadPixels(0, 0, kSize.width, kSize.height, GL_RGBA, GL_UNSIGNED_BYTE, output.data);
    }];

    cv::Mat4b expected(kSize.height, kSize.width, cv::Vec4b(0, 255, 0, 255));
    expect($(output)).to.equalMat($(expected));
  });
});

context(@"binding", ^{
  __block LTScreenFbo *fbo;
  
  beforeEach(^{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    fbo = [[LTScreenFbo alloc] initWithSize:kSize];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  });
  
  afterEach(^{
    fbo = nil;
  });
  
  itShouldBehaveLike(kLTResourceExamples, ^{
    return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:fbo],
             kLTResourceExamplesOpenGLParameterName: @GL_FRAMEBUFFER_BINDING};
  });
  
  it(@"should set the viewport when binding", ^{
    glViewport(1, 2, 3, 4);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    fbo = [[LTScreenFbo alloc] initWithSize:kSize];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, kSize.width, kSize.height);

    __block GLint x, y, width, height;
    [fbo bindAndExecute:^{
      GLint viewport[4];
      glGetIntegerv(GL_VIEWPORT, viewport);
      x = viewport[0];
      y = viewport[1];
      width = viewport[2];
      height = viewport[3];
    }];
    expect(x).to.equal(1);
    expect(y).to.equal(2);
    expect(width).to.equal(3);
    expect(height).to.equal(4);
  });
});

SpecEnd
