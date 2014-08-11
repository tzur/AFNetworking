// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectDrawer.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"

#import "LTMultiRectDrawer.h"
#import "LTSingleRectDrawer.h"

@interface LTRectDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Drawer used for drawing multiple rectangles in a single call.
@property (strong, nonatomic) LTMultiRectDrawer *multiRectDrawer;

/// Drawer used for drawing single rectangles.
@property (strong, nonatomic) LTSingleRectDrawer *singleRectDrawer;

@end

@implementation LTRectDrawer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture {
  return [self initWithProgram:program sourceTexture:texture auxiliaryTextures:nil];
}

- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
    auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture {
  if (self = [super init]) {
    self.singleRectDrawer = [[LTSingleRectDrawer alloc] initWithProgram:program
                                                          sourceTexture:texture
                                                      auxiliaryTextures:uniformToAuxiliaryTexture];
    self.multiRectDrawer = [[LTMultiRectDrawer alloc] initWithProgram:program
                                                        sourceTexture:texture
                                                    auxiliaryTextures:uniformToAuxiliaryTexture];
    self.program = program;
  }
  return self;
}

- (void)setAuxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture {
  [uniformToAuxiliaryTexture
   enumerateKeysAndObjectsUsingBlock:^(NSString *key, LTTexture *texture, BOOL *) {
     [self setAuxiliaryTexture:texture withName:key];
   }];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect {
  [self.singleRectDrawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
}

- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebuffer:(LTFbo *)fbo
        fromRotatedRect:(LTRotatedRect *)sourceRect {
  [self.singleRectDrawer drawRotatedRect:targetRect inFramebuffer:fbo fromRotatedRect:sourceRect];
}

- (void)drawRotatedRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRotatedRects:(NSArray *)sourceRects {
  [self.multiRectDrawer drawRotatedRects:targetRects inFramebuffer:fbo
                        fromRotatedRects:sourceRects];
}

- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect {
  [self.singleRectDrawer drawRect:targetRect inFramebufferWithSize:size fromRect:sourceRect];
}

- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect {
  [self.singleRectDrawer drawRotatedRect:targetRect inFramebufferWithSize:size
                         fromRotatedRect:sourceRect];
}

- (void)drawRotatedRects:(NSArray *)targetRects inFramebufferWithSize:(CGSize)size
        fromRotatedRects:(NSArray *)sourceRects {
  [self.multiRectDrawer drawRotatedRects:targetRects inFramebufferWithSize:size
                        fromRotatedRects:sourceRects];
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setSourceTexture:(LTTexture *)texture {
  [self.singleRectDrawer setSourceTexture:texture];
  [self.multiRectDrawer setSourceTexture:texture];
}

- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name {
  [self.singleRectDrawer setAuxiliaryTexture:texture withName:name];
  [self.multiRectDrawer setAuxiliaryTexture:texture withName:name];
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
  return [self.singleRectDrawer.mandatoryUniforms
          setByAddingObjectsFromSet:self.multiRectDrawer.mandatoryUniforms];
}

@end
