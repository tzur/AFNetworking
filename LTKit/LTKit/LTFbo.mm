// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTDevice.h"
#import "LTGLContext.h"

@interface LTFbo ()

/// Texture associated with the FBO.
@property (strong, nonatomic) LTTexture *texture;

/// Framebuffer identifier.
@property (nonatomic) GLuint framebuffer;

/// Set to the previously bound framebuffer, or \c 0 if the framebuffer is not bound.
@property (nonatomic) GLint previousFramebuffer;

/// Viewport to restore when the current framebuffer unbinds.
@property (nonatomic) CGRect previousViewport;

/// YES if the program is currently bound.
@property (nonatomic) BOOL bound;

@end

@implementation LTFbo

#pragma mark -
#pragma mark Initialization and Setup
#pragma mark -

- (id)initWithTexture:(LTTexture *)texture {
  return [self initWithTexture:texture device:[LTDevice currentDevice]];
}

- (id)initWithTexture:(LTTexture *)texture device:(LTDevice *)device {
  if (self = [super init]) {
    LTParameterAssert(texture);

    if (!texture.name) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's name is 0"];
    }
    if (CGSizeEqualToSize(texture.size, CGSizeZero)) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's size is (0, 0)"];
    }

    [self verifyTextureAsRenderTarget:texture withDevice:device];

    self.previousViewport = CGRectNull;
    self.texture = texture;

    [self createFramebuffer];
  }
  return self;
}

- (void)dealloc {
  if (self.framebuffer) {
    [self bindAndExecute:^{
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
    }];
    glDeleteFramebuffers(1, &_framebuffer);
  }
  LTGLCheckDbg(@"Failed to delete framebuffer: %d", self.framebuffer);
}

- (void)verifyTextureAsRenderTarget:(LTTexture *)texture withDevice:(LTDevice *)device {
  switch (texture.precision) {
    case LTTexturePrecisionByte:
      // Rendering to byte precision is possible by OpenGL ES 2.0 spec.
      break;
    case LTTexturePrecisionHalfFloat:
      if (!device.canRenderToHalfFloatTextures) {
        [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture has a "
         "half-float precision, which is unsupported as a render target on this device"];
      }
      break;
    case LTTexturePrecisionFloat:
      if (!device.canRenderToFloatTextures) {
        [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture has a float "
         "precision, which is unsupported as a render target on this device"];
      }
      break;
  }
}

- (void)createFramebuffer {
  glGenFramebuffers(1, &_framebuffer);
  LTGLCheck(@"Framebuffer creation failed");

  [self bindAndExecute:^{
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           self.texture.name, 0);
    LTGLCheck(@"Failed attaching texture to framebuffer (texture: %@)", self.texture);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d texture: %@)", status, self.framebuffer, self.texture];
    }

    LTGLCheck(@"Error while creating framebuffer");
  }];
}

#pragma mark -
#pragma mark Binding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }
  
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_previousFramebuffer);
  GLint viewport[4];
  glGetIntegerv(GL_VIEWPORT, viewport);
  self.previousViewport = CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3]);

  glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
  glViewport(0, 0, self.texture.size.width, self.texture.size.height);
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  glBindFramebuffer(GL_FRAMEBUFFER, self.previousFramebuffer);
  if (!CGRectIsNull(self.previousViewport)) {
    glViewport(self.previousViewport.origin.x, self.previousViewport.origin.y,
               self.previousViewport.size.width, self.previousViewport.size.height);
  }

  self.previousFramebuffer = 0;
  self.previousViewport = CGRectNull;
  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

- (void)bindAndDraw:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self bindAndExecute:^{
    [self.texture writeToTexture:^{
      block();
    }];
  }];
}

#pragma mark -
#pragma mark Operations
#pragma mark -

- (void)clearWithColor:(GLKVector4)color {
  [self bindAndDraw:^{
    [[LTGLContext currentContext] clearWithColor:color];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (GLuint)name {
  return self.framebuffer;
}

- (CGSize)size {
  return self.texture.size;
}


@end
