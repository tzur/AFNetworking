// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTChannelsPackingProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTChannelsPackingFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTChannelsPackingProcessor ()

/// Array of input single channel textures to pack.
@property (readonly, nonatomic) NSArray<LTTexture *> *inputs;

@end

@implementation LTChannelsPackingProcessor

- (instancetype)initWithInputs:(NSArray<LTTexture *> *)inputs output:(LTTexture *)output {
  LTParameterAssert(inputs.count > 0 && inputs.count <= 4, @"input textures count must be between "
                    "1 to 4 but input count is %lu", (unsigned long)inputs.count);
  [LTChannelsPackingProcessor validateSizeOfInputTextures:inputs outputTexture:output];
  [LTChannelsPackingProcessor validatePixelFormatOfInputTextures:inputs outputTexture:output];

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTChannelsPackingFsh source]
                                   input:inputs[0] andOutput:output]) {
    _inputs = inputs;

    self[[LTChannelsPackingFsh inputTexturesCount]] = @(inputs.count);
    [self setAdditionalInputsInShader];
  }

  return self;
}

+ (void)validateSizeOfInputTextures:(NSArray<LTTexture *> *)inputs
                      outputTexture:(LTTexture *)output {
  for (NSUInteger i = 0; i < inputs.count; ++i) {
    LTParameterAssert(inputs[i].size == output.size, @"input textures and output texture must have "
                      "the same size but input texture at index %lu is of size %@ and output "
                      "texture is of size %@", (unsigned long)i, NSStringFromCGSize(inputs[i].size),
                      NSStringFromCGSize(output.size));
  }
}

+ (void)validatePixelFormatOfInputTextures:(NSArray<LTTexture *> *)inputs
                             outputTexture:(LTTexture *)output {
  LTParameterAssert(output.components == LTGLPixelComponentsRGBA, @"output texture must have 4 "
                    "channels but its pixel format is %@", output.pixelFormat);
  for (NSUInteger i = 0; i < inputs.count; ++i) {
    LTParameterAssert(inputs[i].components == LTGLPixelComponentsR, @"input textures must have "
                      "only 1 channel but input texture pixel format at index %lu is %@",
                      (unsigned long)i, inputs[i].pixelFormat);
    LTParameterAssert(inputs[i].dataType == output.dataType, @"input textures and output texture "
                      "must have the same data type but input texture pixel format at index %lu is "
                      "%@ and output texture pixel format is %@",
                      (unsigned long)i, inputs[i].pixelFormat, output.pixelFormat);
  }
}

- (void)setAdditionalInputsInShader {
  if (self.inputs.count == 1) {
    return;
  }

  [self setAuxiliaryTexture:self.inputs[1] withName:[LTChannelsPackingFsh secondTexture]];
  if (self.inputs.count == 2) {
    return;
  }

  [self setAuxiliaryTexture:self.inputs[2] withName:[LTChannelsPackingFsh thirdTexture]];
  if (self.inputs.count == 3) {
    return;
  }

  [self setAuxiliaryTexture:self.inputs[3] withName:[LTChannelsPackingFsh fourthTexture]];
}

@end

NS_ASSUME_NONNULL_END
