// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureFbo.h"

#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTTexture.h"

@interface LTFbo ()

/// Framebuffer identifier.
@property (readonly, nonatomic) GLuint framebuffer;

@end

@interface LTTextureFbo ()

/// Texture associated with the FBO.
@property (strong, nonatomic) LTTexture *texture;

@end

@implementation LTTextureFbo

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithTexture:(LTTexture *)texture {
  return [self initWithTexture:texture device:[LTDevice currentDevice]];
}

- (id)initWithTexture:(LTTexture *)texture device:(LTDevice *)device {
  LTParameterAssert(texture);
  [self verifyTextureAsRenderTarget:texture withDevice:device];
  if (self = [super initWithFramebufferIdentifier:[self createFramebuffer] size:texture.size
                                         viewport:CGRectFromSize(texture.size)]) {
    [self attachTexture:texture];
    self.texture = texture;
  }
  return self;
}

- (void)dealloc {
  GLuint framebuffer = self.framebuffer;
  if (framebuffer) {
    [self bindAndExecute:^{
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
    }];
    glDeleteFramebuffers(1, &framebuffer);
  }
  LTGLCheckDbg(@"Failed to delete framebuffer: %d", framebuffer);
}

- (void)verifyTextureAsRenderTarget:(LTTexture *)texture withDevice:(LTDevice *)device {
  if (!texture.name) {
    [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's name is 0"];
  }
  if (CGSizeEqualToSize(texture.size, CGSizeZero)) {
    [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's size is (0, 0)"];
  }

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

- (GLuint)createFramebuffer {
  GLuint framebuffer;
  glGenFramebuffers(1, &framebuffer);
  LTGLCheck(@"Framebuffer creation failed");
  return framebuffer;
}

- (void)attachTexture:(LTTexture *)texture {
  [self bindAndExecute:^{
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture.name, 0);
    LTGLCheck(@"Failed attaching texture to framebuffer (texture: %@)", texture);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d texture: %@)", status, self.framebuffer, texture];
    }
    
    LTGLCheck(@"Error while creating framebuffer");
  }];
}

#pragma mark -
#pragma mark Binding
#pragma mark -

- (void)bindAndDraw:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self bindAndExecute:^{
    [self.texture writeToTexture:^{
      block();
    }];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGSize)size {
  return self.texture.size;
}

- (CGRect)viewport {
  return CGRectFromOriginAndSize(CGPointZero, self.size);
}

@end
