// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTDevice.h"
#import "LTGLContext.h"
#import "LTTexture+Protected.h"

@interface LTFbo ()

/// Texture associated with the FBO.
@property (strong, nonatomic) LTTexture *texture;

/// Mip map level of the the texture associated with the FBO.
@property (nonatomic) GLint level;

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

- (instancetype)initWithTexture:(LTTexture *)texture {
  return [self initWithTexture:texture level:0];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(NSUInteger)level {
  return [self initWithTexture:texture level:level device:[LTDevice currentDevice]];
}

- (instancetype)initWithTexture:(LTTexture *)texture device:(LTDevice *)device {
  return [self initWithTexture:texture level:0 device:device];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(NSUInteger)level
                         device:(LTDevice *)device {
  if (self = [super init]) {
    LTParameterAssert(texture);
    LTParameterAssert((GLint)level <= texture.maxMipmapLevel);

    if (!texture.name) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's name is 0"];
    }
    if (CGSizeEqualToSize(texture.size, CGSizeZero)) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's size is (0, 0)"];
    }

    [self verifyTextureAsRenderTarget:texture withDevice:device];

    self.previousViewport = CGRectNull;
    self.texture = texture;
    self.level = (GLint)level;

    [self createFramebuffer];
  }
  return self;
}

- (void)dealloc {
  if (self.framebuffer) {
    [self bindAndExecute:^{
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, self.level);
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
                           self.texture.name, self.level);
    LTGLCheck(@"Failed attaching texture to framebuffer (texture: %@)", self.texture);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d, texture: %@, level: %d)", status, self.framebuffer,
       self.texture, self.level];
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
  CGSize size = self.texture.size / std::pow(2, self.level);
  glViewport(0, 0, size.width, size.height);
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

- (void)setContextWithRenderingToScreen:(BOOL)renderingToScreen andDraw:(LTVoidBlock)block {
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.renderingToScreen = renderingToScreen;
    // New framebuffer is attached, there's no point of keeping the previous scissor tests.
    context.scissorTestEnabled = NO;
    block();
  }];
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    [self setContextWithRenderingToScreen:NO andDraw:block];
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

- (void)bindAndDrawOnScreen:(LTVoidBlock)block {
  [self bindAndDraw:^{
    [self setContextWithRenderingToScreen:YES andDraw:block];
  }];
}

#pragma mark -
#pragma mark Operations
#pragma mark -

- (void)clearWithColor:(LTVector4)color {
  // Adjust the texture's fill color in case it has only a single level.
  if (!self.texture.maxMipmapLevel) {
    self.texture.fillColor = color;
  } else if (self.texture.fillColor != color) {
    self.texture.fillColor = LTVector4Null;
  }

  [self bindAndExecute:^{
    [self.texture performWithoutUpdatingFillColor:^{
      [self.texture writeToTexture:^{
        [[LTGLContext currentContext] clearWithColor:color];
      }];
    }];
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

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  return [self.texture performSelector:@selector(debugQuickLookObject)];
}

@end
