// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBrushShaderVsh.h"
#import "LTShaderStorage+LTTextureBrushShaderFsh.h"
#import "LTShaderStorage+LTTextureBrushPremultipliedShaderFsh.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;
@end

@interface LTTextureBrush ()

/// Texture holding the brush. Cannot be set to \c nil, and default value is a 1x1 rgba texture with
/// maximal intensity in all channels.
@property (strong, nonatomic) LTTexture *texture;

/// Program used when the \c premultipliedAlpha property is set to \c NO. This shader blends under
/// the assumption that both the input texture and output canvas are not premultiplied.
@property (strong, nonatomic) LTProgram *normalProgram;

/// Program used when the \c premultipliedAlpha property is set to \c YES. This shader blends under
/// the assumption that both the input texture and output canvas are premultiplied.
@property (strong, nonatomic) LTProgram *premultipliedProgram;

/// Drawer used when the \c premultipliedAlpha property is set to \c NO.
@property (strong, nonatomic) LTRectDrawer *normalDrawer;

/// Drawer used when the \c premultipliedAlpha property is set to \c NO.
@property (strong, nonatomic) LTRectDrawer *premultipliedDrawer;

@end

@implementation LTTextureBrush

/// Override the default spacing of the \c LTBrush.
static const CGFloat kDefaultSpacing = 2.0;

static CGSize kDefaultTextureSize = CGSizeMake(1, 1);

- (instancetype)init {
  if (self = [super init]) {
    [self setTextureBrushDefaults];
  }
  return self;
}

- (void)setTextureBrushDefaults {
  self.spacing = kDefaultSpacing;
}

- (LTTexture *)createTexture {
  cv::Mat4b defaultMat(kDefaultTextureSize.height, kDefaultTextureSize.width,
                       cv::Vec4b(255, 255, 255, 255));
  return [LTTexture textureWithImage:defaultMat];
}

- (LTProgram *)createProgram {
  return self.premultipliedAlpha ? self.premultipliedProgram : self.normalProgram;
}

- (LTRectDrawer *)createDrawer {
  return self.premultipliedAlpha ? self.premultipliedDrawer : self.normalDrawer;
}

- (void)updateProgramForCurrentProperties {
  if (self.premultipliedAlpha) {
    self.premultipliedProgram[[LTTextureBrushPremultipliedShaderFsh flow]] = @(self.flow);
    self.premultipliedProgram[[LTTextureBrushPremultipliedShaderFsh opacity]] = @(self.opacity);
    self.premultipliedProgram[[LTTextureBrushPremultipliedShaderFsh intensity]] = $(self.intensity);
  } else {
    self.normalProgram[[LTTextureBrushShaderFsh flow]] = @(self.flow);
    self.normalProgram[[LTTextureBrushShaderFsh opacity]] = @(self.opacity);
    self.normalProgram[[LTTextureBrushShaderFsh intensity]] = $(self.intensity);
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTexture:(LTTexture *)texture {
  LTParameterAssert(texture.format == LTTextureFormatRGBA);
  _texture = texture;
  [self.normalDrawer setSourceTexture:texture];
  [self.premultipliedDrawer setSourceTexture:texture];
}

- (void)setPremultipliedAlpha:(BOOL)premultipliedAlpha {
  if (premultipliedAlpha == _premultipliedAlpha) {
    return;
  }
  
  _premultipliedAlpha = premultipliedAlpha;
  self.program = self.premultipliedAlpha ? self.premultipliedProgram : self.normalProgram;
  self.drawer = self.premultipliedAlpha ? self.premultipliedDrawer : self.normalDrawer;
  [self updateProgramForCurrentProperties];
}

- (LTProgram *)normalProgram {
  if (!_normalProgram) {
    _normalProgram = [[LTProgram alloc] initWithVertexSource:[LTBrushShaderVsh source]
                                              fragmentSource:[LTTextureBrushShaderFsh source]];
  }
  return _normalProgram;
}

- (LTProgram *)premultipliedProgram {
  if (!_premultipliedProgram) {
    _premultipliedProgram =
        [[LTProgram alloc] initWithVertexSource:[LTBrushShaderVsh source]
                                 fragmentSource:[LTTextureBrushPremultipliedShaderFsh source]];
  }
  return _premultipliedProgram;
}

- (LTRectDrawer *)normalDrawer {
  if (!_normalDrawer) {
    _normalDrawer = [[LTRectDrawer alloc] initWithProgram:self.normalProgram
                                            sourceTexture:self.texture];
  }
  return _normalDrawer;
}

- (LTRectDrawer *)premultipliedDrawer {
  if (!_premultipliedDrawer) {
    _premultipliedDrawer = [[LTRectDrawer alloc] initWithProgram:self.premultipliedProgram
                                                   sourceTexture:self.texture];
  }
  return _premultipliedDrawer;
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
