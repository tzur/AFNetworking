// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTEdgesMaskProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTEdgesMaskFsh.h"
#import "LTShaderStorage+LTEdgesMaskVsh.h"
#import "LTTexture+Factory.h"

@interface LTEdgesMaskProcessor ()

/// Offset between the pixel and it's south-east neighbour in the shader.
@property (nonatomic) GLKVector2 texelOffset;

/// If \c YES, the smooth processor has created a smooth texture, \c NO otherwise.
@property (nonatomic) BOOL smoothTextureCreated;

/// Smooth texture that is used to compute the edges.
@property (strong, nonatomic) LTTexture *smoothTexture;

// Input texture that is used to compute the edges.
@property (strong, nonatomic) LTTexture *inputTexture;

@end

@implementation LTEdgesMaskProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTEdgesMaskVsh source]
                                                fragmentSource:[LTEdgesMaskFsh source]];
  self.smoothTexture = [self allocateSmoothTexture:input outoutSize:output.size];
  if (self = [super initWithProgram:program input:self.smoothTexture andOutput:output]) {
    self.texelOffset = GLKVector2Make(1.0 / input.size.width, 1.0 / input.size.height);
    self.edgesMode = LTEdgesModeGrey;
    self.smoothTextureCreated = NO;
    self.inputTexture = input;
  }
  return self;
}

- (LTTexture *)allocateSmoothTexture:(LTTexture *)input outoutSize:(CGSize)outputSize {
  CGFloat width = MIN(input.size.height, outputSize.width);
  CGFloat height = MIN(input.size.height, outputSize.height);
  LTTexture *smoothTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  return smoothTexture;
}

- (void)setTexelOffset:(GLKVector2)texelOffset {
  _texelOffset = texelOffset;
  self[[LTEdgesMaskVsh texelOffset]] = $(texelOffset);
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)processSmoothTexture {
  LTBilateralFilterProcessor *smoother = [[LTBilateralFilterProcessor alloc]
      initWithInput:self.inputTexture outputs:@[self.smoothTexture]];
  smoother.iterationsPerOutput = @[@(4)];
  smoother.rangeSigma = 0.1;
  [smoother process];
}

- (void)process {
  if (!self.smoothTextureCreated) {
    [self processSmoothTexture];
    self.smoothTextureCreated = YES;
  }
  return [super process];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setEdgesMode:(LTEdgesMode)edgesMode {
  _edgesMode = edgesMode;
  self[[LTEdgesMaskFsh edgesMode]] = @(edgesMode);
}

@end
