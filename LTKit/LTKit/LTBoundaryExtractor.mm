// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBoundaryExtractor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBoundaryExtractorFsh.h"
#import "LTShaderStorage+LTBoundaryExtractorVsh.h"
#import "LTTexture.h"

@interface LTBoundaryExtractor ()

@property (strong, nonatomic) LTTexture *input;
@property (strong, nonatomic) LTTexture *output;

@property (nonatomic) GLKVector2 texelOffset;

@end

@implementation LTBoundaryExtractor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program =
      [[LTProgram alloc] initWithVertexSource:[LTBoundaryExtractorVsh source]
                               fragmentSource:[LTBoundaryExtractorFsh source]];
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
    result = [super process];
  }];
  
  return result;
}

- (void)setTexelOffset:(GLKVector2)texelOffset {
  _texelOffset = texelOffset;
  self[[LTBoundaryExtractorVsh texelOffset]] = $(texelOffset);
}

@end
