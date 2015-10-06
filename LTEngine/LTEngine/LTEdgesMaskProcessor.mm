// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTEdgesMaskProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTEdgesMaskFsh.h"
#import "LTShaderStorage+LTEdgesMaskVsh.h"
#import "LTTexture+Factory.h"

/// Types of edges that the processor can create.
typedef NS_ENUM(NSUInteger, LTEdgesMode) {
  LTEdgesModeGrey = 0,
  LTEdgesModeColor
};

/// Helper class used to actually compute the edges from the input texture.
@interface LTEdgeMaskSubprocessor : LTOneShotImageProcessor
@end

@implementation LTEdgeMaskSubprocessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTParameterAssert(output.format == LTTextureFormatRed || output.format == LTTextureFormatRGBA);
  if (self = [super initWithVertexSource:[LTEdgesMaskVsh source]
                          fragmentSource:[LTEdgesMaskFsh source] input:input andOutput:output]) {
    self[[LTEdgesMaskVsh texelOffset]] = $(LTVector2(1.0 / input.size.width,
                                                          1.0 / input.size.height));
    self[[LTEdgesMaskFsh edgesMode]] =
        @((output.format == LTTextureFormatRed) ? LTEdgesModeGrey : LTEdgesModeColor);
  }
  return self;
}

@end

@interface LTEdgesMaskProcessor ()

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

@end

@implementation LTEdgesMaskProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTParameterAssert(output.format == LTTextureFormatRed || output.format == LTTextureFormatRGBA);
  if (self = [super init]) {
    self.inputTexture = input;
    self.outputTexture = output;
  }
  return self;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  LTTexture *smoothTexture = [self createSmoothTexture];
  LTEdgeMaskSubprocessor *processor = [[LTEdgeMaskSubprocessor alloc]
                                       initWithInput:smoothTexture output:self.outputTexture];
  [processor process];
}

- (LTTexture *)createSmoothTexture {
  CGFloat width = MIN(self.inputTexture.size.width, self.outputTexture.size.width);
  CGFloat height = MIN(self.outputTexture.size.height, self.outputTexture.size.height);
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  LTBilateralFilterProcessor *smoother = [[LTBilateralFilterProcessor alloc]
                                          initWithInput:self.inputTexture outputs:@[texture]];
  smoother.iterationsPerOutput = @[@(2)];
  smoother.rangeSigma = 0.2;
  [smoother process];
  return texture;
}

@end
