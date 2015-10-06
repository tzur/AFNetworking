// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

#import "LTFbo.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBrushVsh.h"
#import "LTShaderStorage+LTTextureBrushFsh.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()

- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects;

@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;

@end

@interface LTTextureBrush ()

/// Texture holding the brush. Cannot be set to \c nil, and default value is a 1x1 rgba texture with
/// maximal intensity in all channels.
@property (strong, nonatomic) LTTexture *texture;

@end

@implementation LTTextureBrush

static CGSize kDefaultTextureSize = CGSizeMake(1, 1);

- (LTTexture *)createTexture {
  cv::Mat4b defaultMat(kDefaultTextureSize.height, kDefaultTextureSize.width,
                       cv::Vec4b(255, 255, 255, 255));
  return [LTTexture textureWithImage:defaultMat];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushVsh source]
                                  fragmentSource:[LTTextureBrushFsh source]];
}

- (void)updateProgramForCurrentProperties {
  self.program[[LTTextureBrushFsh premultiplied]] = @(self.premultipliedAlpha);
  self.program[[LTTextureBrushFsh flow]] = @(self.flow);
  self.program[[LTTextureBrushFsh opacity]] = @(self.opacity);
  self.program[[LTTextureBrushFsh intensity]] = $(self.intensity);
}

- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects {
  self.program[[LTTextureBrushFsh singleChannelTarget]] = @(fbo.texture.channels == 1);
  [super drawRects:targetRects inFramebuffer:fbo fromRects:sourceRects];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)defaultSpacing {
  return 2.0;
}

- (void)setTexture:(LTTexture *)texture {
  LTParameterAssert(texture.format == LTTextureFormatRGBA);
  _texture = texture;
  [self.drawer setSourceTexture:texture];
}

- (void)setPremultipliedAlpha:(BOOL)premultipliedAlpha {
  if (premultipliedAlpha == _premultipliedAlpha) {
    return;
  }
  
  _premultipliedAlpha = premultipliedAlpha;
  [self updateProgramForCurrentProperties];
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"spacing", @"flow", @"opacity", @"angle"];
}

#pragma mark -
#pragma mark For Testing
#pragma mark -

- (void)setSingleTexture:(LTTexture __unused *)texture {
  LTMethodNotImplemented();
}

@end
