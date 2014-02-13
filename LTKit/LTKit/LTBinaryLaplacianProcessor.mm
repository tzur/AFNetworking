// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBinaryLaplacianProcessor.h"

#import "LTTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBinaryLaplacianFsh.h"
#import "LTShaderStorage+LTBinaryLaplacianVsh.h"

@interface LTBinaryLaplacianProcessor ()

@property (strong, nonatomic) LTTexture *input;
@property (strong, nonatomic) LTTexture *output;

@property (nonatomic) GLKVector2 texelOffset;

@end

@implementation LTBinaryLaplacianProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program =
      [[LTProgram alloc] initWithVertexSource:[LTBinaryLaplacianVsh source]
                               fragmentSource:[LTBinaryLaplacianFsh source]];
  if (self = [super initWithProgram:program input:input andOutput:output]) {
    self.input = input;
    self.output = output;
    self.texelOffset = GLKVector2Make(1.0 / input.size.width, 1.0 / input.size.height);
  }
  return self;
}

- (id<LTImageProcessorOutput>)process {
  __block id<LTImageProcessorOutput> result;

  [self.input executeAndPreserveParameters:^{
    self.input.minFilterInterpolation = LTTextureInterpolationNearest;
    self.input.magFilterInterpolation = LTTextureInterpolationNearest;

    result = [super process];
  }];
  
  return result;
}

- (void)setTexelOffset:(GLKVector2)texelOffset {
  _texelOffset = texelOffset;
  self[[LTBinaryLaplacianVsh texelOffset]] = $(texelOffset);
}

@end
