// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMultiTextureBrush.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTRandom.h"
#import "LTRotatedRect+UIColor.h"
#import "LTShaderStorage+LTBrushFsh.h"
#import "UIColor+Vector.h"

@interface LTBrush ()
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;
@property (strong, nonatomic) LTTexture *texture;
@end

@implementation LTMultiTextureBrush

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithRandom:(LTRandom *)random {
  if (self = [super initWithRandom:random]) {
    [self setMultiTextureBrushDefaults];
  }
  return self;
}

- (void)setMultiTextureBrushDefaults {
  _textures = @[self.texture];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects {
  LTParameterAssert(targetRects.count == sourceRects.count);
  [fbo bindAndDraw:^{
    for (NSUInteger i = 0; i < targetRects.count; ++i) {
      LTRotatedRect *targetRect = targetRects[i];
      if (targetRect.color) {
        self.program[[LTBrushFsh intensity]] = $(targetRect.color.glkVector);
      }
      
      uint textureIdx = [self.random randomUnsignedIntegerBelow:(uint)self.textures.count];
      [self.drawer setSourceTexture:self.textures[textureIdx]];
      [self.drawer drawRotatedRect:targetRects[i] inBoundFramebufferWithSize:fbo.size
                   fromRotatedRect:sourceRects[i]];
    }
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTextures:(NSArray *)textures {
  LTParameterAssert(textures.count);
  CGSize size = [textures.firstObject size];
  for (LTTexture *texture in textures) {
    LTParameterAssert(texture.format == LTTextureFormatRGBA);
    LTParameterAssert(texture.size == size, @"all textures should have the same size");
  }
  _textures = [textures copy];
  self.texture = self.textures.firstObject;
}

#pragma mark -
#pragma mark For Testing
#pragma mark -

- (void)setSingleTexture:(LTTexture *)texture {
  self.textures = @[texture];
}

@end
