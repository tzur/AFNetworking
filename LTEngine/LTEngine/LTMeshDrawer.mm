// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzamn.

#import "LTMeshDrawer.h"

#import "LTForegroundBackgroundDrawer.h"
#import "LTMeshBaseDrawer.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTSingleRectDrawer.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMeshDrawer ()

/// Auxiliary drawer for drawing the mesh in the mesh source area and passing through the source
/// texture in the rest of the area.
@property (readonly, nonatomic) LTForegroundBackgroundDrawer *foregroundBackgroundDrawer;

/// Base drawer used to draw the mesh in the foreground.
@property (readonly, nonatomic) LTMeshBaseDrawer *meshBaseDrawer;

/// Drawer used to draw the background with no displacement.
@property (readonly, nonatomic) LTSingleRectDrawer *backgroundDrawer;

@end

@implementation LTMeshDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProgram:(__unused LTProgram *)program
                  sourceTexture:(__unused LTTexture *)texture {
  LTMethodNotImplemented();
}

- (instancetype)initWithProgram:(__unused LTProgram *)program
                  sourceTexture:(__unused LTTexture *)texture
              auxiliaryTextures:(__unused NSDictionary *)uniformToAuxiliaryTexture {
  LTMethodNotImplemented();
}

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture {
  return [self initWithSourceTexture:sourceTexture meshTexture:meshTexture
                      fragmentSource:[LTPassthroughShaderFsh source]];
}

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                       meshSourceRect:(CGRect)meshSourceRect
                          meshTexture:(LTTexture *)meshTexture {
  return [self initWithSourceTexture:sourceTexture meshSourceRect:meshSourceRect
                         meshTexture:meshTexture fragmentSource:[LTPassthroughShaderFsh source]];
}

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource {
  return [self initWithSourceTexture:sourceTexture meshSourceRect:CGRectFromSize(sourceTexture.size)
                         meshTexture:meshTexture fragmentSource:fragmentSource];
}


- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                       meshSourceRect:(CGRect)meshSourceRect meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource {
  if (self = [super init]) {
    LTMeshBaseDrawer *meshBaseDrawer =
        [[LTMeshBaseDrawer alloc] initWithSourceTexture:sourceTexture meshSourceRect:meshSourceRect
                                            meshTexture:meshTexture fragmentSource:fragmentSource];
    LTProgram *backgroundProgram =
        [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                 fragmentSource:fragmentSource];
    LTSingleRectDrawer *backgroundDrawer =
        [[LTSingleRectDrawer alloc] initWithProgram:backgroundProgram sourceTexture:sourceTexture];
    _foregroundBackgroundDrawer =
        [[LTForegroundBackgroundDrawer alloc] initWithForegroundDrawer:meshBaseDrawer
                                                      backgroundDrawer:backgroundDrawer
                                                        foregroundRect:meshSourceRect];
  }

  return self;
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [self.foregroundBackgroundDrawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  [self.foregroundBackgroundDrawer drawRect:targetRect inFramebufferWithSize:size
                                   fromRect:sourceRect];
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setSourceTexture:(LTTexture *)texture {
  [self.meshBaseDrawer setSourceTexture:texture];
  [self.backgroundDrawer setSourceTexture:texture];
}

- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name {
  [self.meshBaseDrawer setAuxiliaryTexture:texture withName:name];
  [self.backgroundDrawer setAuxiliaryTexture:texture withName:name];
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  [self.meshBaseDrawer setUniform:name withValue:value];
  [self.backgroundDrawer setUniform:name withValue:value];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self setUniform:key withValue:obj];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self.meshBaseDrawer objectForKeyedSubscript:key];
}

- (id)uniformForName:(NSString *)name {
  return [self.meshBaseDrawer uniformForName:name];
}

- (NSSet *)mandatoryUniforms {
  return [self.meshBaseDrawer.mandatoryUniforms
          setByAddingObjectsFromSet:self.backgroundDrawer.mandatoryUniforms];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (BOOL)drawWireframe {
  return self.meshBaseDrawer.drawWireframe;
}

- (void)setDrawWireframe:(BOOL)drawWireframe {
  self.meshBaseDrawer.drawWireframe = drawWireframe;
}

- (LTMeshBaseDrawer *)meshBaseDrawer {
  return self.foregroundBackgroundDrawer.foregroundDrawer;
}

- (LTSingleRectDrawer *)backgroundDrawer {
  return (LTSingleRectDrawer *)self.foregroundBackgroundDrawer.backgroundDrawer;
}

@end

NS_ASSUME_NONNULL_END
