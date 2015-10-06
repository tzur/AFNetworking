// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadDrawer.h"

#import "LTFbo.h"
#import "LTProgram.h"
#import "LTQuad.h"

@interface LTQuadDrawer ()

/// Program to use when drawing the rect/quad.
@property (strong, nonatomic) LTProgram *program;

/// Drawer used for drawing single quadrilaterals.
@property (strong, nonatomic) LTSingleQuadDrawer *singleQuadDrawer;

@end

@implementation LTQuadDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture {
  return [self initWithProgram:program sourceTexture:texture auxiliaryTextures:nil];
}

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
              auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture {
  if (self = [super init]) {
    self.singleQuadDrawer = [[LTSingleQuadDrawer alloc] initWithProgram:program
                                                          sourceTexture:texture
                                                      auxiliaryTextures:uniformToAuxiliaryTexture];
    self.program = program;
  }
  return self;
}

#pragma mark -
#pragma mark Drawing (CGRect)
#pragma mark -


- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [self.singleQuadDrawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  [self.singleQuadDrawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
}

#pragma mark -
#pragma mark Drawing (LTQuad)
#pragma mark -

- (void)drawQuad:(LTQuad *)targetQuad inFramebuffer:(LTFbo *)fbo fromQuad:(LTQuad *)sourceQuad {
  [self.singleQuadDrawer drawQuad:targetQuad inFramebuffer:fbo fromQuad:sourceQuad];
}

- (void)drawQuad:(LTQuad *)targetQuad inFramebufferWithSize:(CGSize)size
        fromQuad:(LTQuad *)sourceQuad {
  [self.singleQuadDrawer drawQuad:targetQuad inFramebufferWithSize:size fromQuad:sourceQuad];
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setSourceTexture:(LTTexture *)texture {
  [self.singleQuadDrawer setSourceTexture:texture];
}

- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name {
  [self.singleQuadDrawer setAuxiliaryTexture:texture withName:name];
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  LTAssert(![name isEqualToString:@"position"] && ![name isEqualToString:@"texcoord"],
           @"Uniform name cannot be position or texcoord");

  self.program[name] = value;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self setUniform:key withValue:obj];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self uniformForName:key];
}

- (id)uniformForName:(NSString *)name {
  return self.program[name];
}

- (NSSet *)mandatoryUniforms {
  return self.singleQuadDrawer.mandatoryUniforms;
}

@end
